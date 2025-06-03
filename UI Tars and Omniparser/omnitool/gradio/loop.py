"""
Agentic sampling loop that calls the Anthropic API and local implenmentation of anthropic-defined computer use tools.
"""
from collections.abc import Callable
from enum import StrEnum

from anthropic import APIResponse
from anthropic.types import (
    TextBlock,
)
from anthropic.types.beta import (
    BetaContentBlock,
    BetaMessage,
    BetaMessageParam
)
from tools import ToolResult

from agent.llm_utils.omniparserclient import OmniParserClient
from agent.anthropic_agent import AnthropicActor
from agent.vlm_agent import VLMAgent
from agent.vlm_agent_with_orchestrator import VLMOrchestratedAgent
from executor.anthropic_executor import AnthropicExecutor

BETA_FLAG = "computer-use-2024-10-22"

class APIProvider(StrEnum):
    ANTHROPIC = "anthropic"
    BEDROCK = "bedrock"
    VERTEX = "vertex"
    OPENAI = "openai"


PROVIDER_TO_DEFAULT_MODEL_NAME: dict[APIProvider, str] = {
    APIProvider.ANTHROPIC: "claude-3-5-sonnet-20241022",
    APIProvider.BEDROCK: "anthropic.claude-3-5-sonnet-20241022-v2:0",
    APIProvider.VERTEX: "claude-3-5-sonnet-v2@20241022",
    APIProvider.OPENAI: "gpt-4o",
}

def sampling_loop_sync(
    *,
    model: str,
    provider: APIProvider | None,
    messages: list[BetaMessageParam],
    output_callback: Callable[[BetaContentBlock], None],
    tool_output_callback: Callable[[ToolResult, str], None],
    api_response_callback: Callable[[APIResponse[BetaMessage]], None],
    api_key: str,
    only_n_most_recent_images: int | None = 2,
    max_tokens: int = 4096,
    omniparser_url: str,
    save_folder: str = "./uploads"
):
    """
    Synchronous agentic sampling loop for the assistant/tool interaction of computer use.
    """
    print('in sampling_loop_sync, model:', model)
    
    try:
        omniparser_client = OmniParserClient(url=f"http://{omniparser_url}/parse/")
    except Exception as e:
        raise Exception(f"Failed to initialize OmniParser client: {str(e)}")
    
    # Initialize the appropriate actor based on the model
    try:
        if model == "claude-3-5-sonnet-20241022":
            # Register Actor and Executor
            actor = AnthropicActor(
                model=model, 
                provider=provider,
                api_key=api_key, 
                api_response_callback=api_response_callback,
                max_tokens=max_tokens,
                only_n_most_recent_images=only_n_most_recent_images
            )
        elif model in set(["omniparser + gpt-4o", "omniparser + o1", "omniparser + o3-mini", "omniparser + R1", "omniparser + qwen2.5vl"]):
            actor = VLMAgent(
                model=model,
                provider=provider,
                api_key=api_key,
                api_response_callback=api_response_callback,
                output_callback=output_callback,
                max_tokens=max_tokens,
                only_n_most_recent_images=only_n_most_recent_images
            )
        elif model in set(["omniparser + gpt-4o-orchestrated", "omniparser + o1-orchestrated", "omniparser + o3-mini-orchestrated", "omniparser + R1-orchestrated", "omniparser + qwen2.5vl-orchestrated"]):
            actor = VLMOrchestratedAgent(
                model=model,
                provider=provider,
                api_key=api_key,
                api_response_callback=api_response_callback,
                output_callback=output_callback,
                max_tokens=max_tokens,
                only_n_most_recent_images=only_n_most_recent_images,
                save_folder=save_folder
            )
        else:
            raise ValueError(f"Model {model} not supported. Available models: claude-3-5-sonnet-20241022, omniparser + gpt-4o, omniparser + o1, omniparser + o3-mini, omniparser + R1, omniparser + qwen2.5vl, and their orchestrated variants.")
    except Exception as e:
        raise Exception(f"Failed to initialize actor for model '{model}': {str(e)}")
    
    try:
        executor = AnthropicExecutor(
            output_callback=output_callback,
            tool_output_callback=tool_output_callback,
        )
    except Exception as e:
        raise Exception(f"Failed to initialize executor: {str(e)}")
    
    print(f"Model Inited: {model}, Provider: {provider}")
    
    tool_result_content = None
    loop_count = 0
    max_iterations = 50  # Prevent infinite loops
    
    print(f"Start the message loop. User messages: {messages}")
    
    try:
        if model == "claude-3-5-sonnet-20241022": # Anthropic loop
            while loop_count < max_iterations:
                loop_count += 1
                print(f"Loop iteration {loop_count}")
                
                try:
                    parsed_screen = omniparser_client() # parsed_screen: {"som_image_base64": dino_labled_img, "parsed_content_list": parsed_content_list, "screen_info"}
                    screen_info_block = TextBlock(text='Below is the structured accessibility information of the current UI screen, which includes text and icons you can operate on, take these information into account when you are making the prediction for the next action. Note you will still need to take screenshot to get the image: \n' + parsed_screen['screen_info'], type='text')
                    screen_info_dict = {"role": "user", "content": [screen_info_block]}
                    messages.append(screen_info_dict)
                    tools_use_needed = actor(messages=messages)

                    for message, tool_result_content in executor(tools_use_needed, messages):
                        yield message
                
                    if not tool_result_content:
                        print(f"Task completed after {loop_count} iterations")
                        return messages

                    messages.append({"content": tool_result_content, "role": "user"})
                    
                except Exception as e:
                    print(f"Error in loop iteration {loop_count}: {str(e)}")
                    raise Exception(f"Failed at iteration {loop_count}: {str(e)}")
        
        elif model in set(["omniparser + gpt-4o", "omniparser + o1", "omniparser + o3-mini", "omniparser + R1", "omniparser + qwen2.5vl", "omniparser + gpt-4o-orchestrated", "omniparser + o1-orchestrated", "omniparser + o3-mini-orchestrated", "omniparser + R1-orchestrated", "omniparser + qwen2.5vl-orchestrated"]):
            while loop_count < max_iterations:
                loop_count += 1
                print(f"Loop iteration {loop_count}")
                
                try:
                    parsed_screen = omniparser_client()
                    tools_use_needed, vlm_response_json = actor(messages=messages, parsed_screen=parsed_screen)

                    for message, tool_result_content in executor(tools_use_needed, messages):
                        yield message
                
                    if not tool_result_content:
                        print(f"Task completed after {loop_count} iterations")
                        return messages
                    
                    messages.append({"content": tool_result_content, "role": "user"})
                    
                except Exception as e:
                    print(f"Error in loop iteration {loop_count}: {str(e)}")
                    raise Exception(f"Failed at iteration {loop_count}: {str(e)}")
        
        # If we reach here, we hit the max iterations
        print(f"Warning: Stopped after {max_iterations} iterations to prevent infinite loop")
        return messages
        
    except Exception as e:
        print(f"Error in sampling loop: {str(e)}")
        raise Exception(f"Sampling loop failed: {str(e)}")