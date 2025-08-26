#!/usr/bin/env python3
import sys
import torch
from PIL import Image
from torchvision import transforms

# ---- Load TorchScript model ----
model = torch.jit.load("model.pt")
model.eval()

# ---- ImageNet preprocessing for MobileNetV2 ----
preprocess = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225]),
])

# ---- Try to get labels (optional) ----
labels = None
try:
    from torchvision.models import MobileNet_V2_Weights
    labels = list(MobileNet_V2_Weights.DEFAULT.meta["categories"])
except Exception:
    labels = None

def main():
    if len(sys.argv) != 2:
        print("Usage: python inference.py /path/to/image.jpg")
        sys.exit(1)

    img_path = sys.argv[1]
    img = Image.open(img_path).convert("RGB")
    x = preprocess(img).unsqueeze(0)  # [1,3,224,224]

    with torch.inference_mode():
        logits = model(x)
        probs = torch.softmax(logits, dim=1)
        top_p, top_i = torch.topk(probs, k=3, dim=1)

    top_p = top_p[0].tolist()
    top_i = top_i[0].tolist()

    print(f"Image: {img_path}")
    print("Top-3 predictions:")
    for rank, (idx, p) in enumerate(zip(top_i, top_p), start=1):
        name = labels[idx] if labels and idx < len(labels) else f"class_{idx}"
        print(f"{rank}. {name} — {p*100:.2f}% (id={idx})")

if __name__ == "__main__":
    main()
