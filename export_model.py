import torch
import torchvision.models as models

# Завантаження попередньо натренованої моделі ResNet18
model = models.mobilenet_v2(weights=models.MobileNet_V2_Weights.DEFAULT)
model.eval()  # Перехід у режим оцінки (inference)

# Створення "манекена" для трасування моделі
dummy_input = torch.rand(1, 3, 224, 224)

# Трасування моделі в TorchScript
traced_model = torch.jit.trace(model, dummy_input)

# Збереження моделі
traced_model.save("./model.pt")
print("✅ Model saved to model.pt")