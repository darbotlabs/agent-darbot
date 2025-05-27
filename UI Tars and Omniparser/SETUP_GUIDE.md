# Instructions to set up OmniParser

1. **Install dependencies**
   - Create a new conda environment and install requirements:
     ```sh
     conda create -n "omni" python==3.12
     conda activate omni
     pip install -r requirements.txt
     ```

2. **Download model weights**
   - Create a `weights` directory in the root of `OmniParser-master`.
   - Download the V2 model checkpoints from HuggingFace:
     ```sh
     mkdir weights
     for f in icon_detect/{train_args.yaml,model.pt,model.yaml} icon_caption/{config.json,generation_config.json,model.safetensors}; do huggingface-cli download microsoft/OmniParser-v2.0 "$f" --local-dir weights; done
     mv weights/icon_caption weights/icon_caption_florence
     ```
   - Alternatively, download manually from: https://huggingface.co/microsoft/OmniParser-v2.0

3. **Verify folder structure**
   - `weights/icon_detect/` should contain YOLO model files.
   - `weights/icon_caption_florence/` should contain caption model files.

4. **Run the Gradio demo**
   - Start the demo with:
     ```sh
     python gradio_demo.py
     ```

5. **Try the notebook**
   - Open `demo.ipynb` for example usage.

6. **(Optional) Explore code**
   - Main logic: `util/`, `gradio_demo.py`, `omnitool/`
   - For custom use, see `util/omniparser.py` for programmatic API.

---

**Note:**
- GPU (CUDA) is recommended for best performance.
- Some OCR features require additional dependencies (see `requirements.txt`).
- For issues, check the [README.md](README.md) and [LICENSE](LICENSE).




