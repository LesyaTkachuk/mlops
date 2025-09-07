import mlflow
import joblib
from sklearn.datasets import load_iris
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, log_loss
import os
import datetime


def push_to_prometheus(accuracy, loss, job_name="mlflow_training"):
    """
    Простая функция для отправки метрик в Prometheus Pushgateway
    """
    try:
        from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
        
        # URL Pushgateway (можно задать через переменную окружения)
        gateway_url = os.environ.get('PUSHGATEWAY_URL', 'localhost:9091')
        
        # Создаем реестр метрик
        registry = CollectorRegistry()
        
        # Создаем метрики
        accuracy_gauge = Gauge('mlflow_accuracy', 'Model accuracy', registry=registry)
        loss_gauge = Gauge('mlflow_loss', 'Model loss', registry=registry)
        
        # Устанавливаем значения
        accuracy_gauge.set(accuracy)
        loss_gauge.set(loss)
        
        # Отправляем в Pushgateway
        push_to_gateway(gateway_url, job=job_name, registry=registry)
        print(f"📊 Метрики відправлені в Pushgateway: {gateway_url}")
        
    except ImportError:
        print("⚠️ prometheus_client не установлен. Для установки: pip install prometheus_client")
    except Exception as e:
        print(f"⚠️ Не вдалося відправити метрики в Pushgateway: {e}")
        print("💡 Провірте доступніст Pushgateway і налаштування мережі")


if not os.environ.get('MLFLOW_TRACKING_URI'):
    print("❌ Змінна MLFLOW_TRACKING_URI не встановлена")
    exit(1)
if not os.environ.get('MLFLOW_TRACKING_USERNAME'):
    print("❌ Змінна MLFLOW_TRACKING_USERNAME не встановлена")
    exit(1)
if not os.environ.get('MLFLOW_TRACKING_PASSWORD'):
    print("❌ Змінна MLFLOW_TRACKING_PASSWORD не встановлена")
    exit(1)

# Параметри, які хочемо варіювати
learning_rate = [0.01, 0.1, 1.0]
epochs = [200, 400, 800]

# === Старт логування ===
mlflow.set_experiment("MLOps Classification")

# Унікальний timestamp
timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

print(f"🚀 Запускаю перебір гіперпараметрів: {len(learning_rate) * len(epochs)} комбінацій")

# Дані (завантажуємо один раз)
X, y = load_iris(return_X_y=True)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.25, random_state=42, stratify=y
)

best_acc = -1.0
best_model = None
best_params = None

for lr in learning_rate:
    for ep in epochs:
        run_name = f"iris_lr_{lr}_epochs_{ep}_{timestamp}"
        print(f"➡️  Треную: {run_name}")

        with mlflow.start_run(run_name=run_name):
            # Логування параметрів (мінімально та прямо)
            mlflow.log_param("learning_rate_as_C", lr)  # інтерпретуємо learning_rate як C
            mlflow.log_param("epochs", ep)
            mlflow.log_param("model_version", "1.0.0")
            mlflow.log_param("model_name", "iris_model")

            # Тренування моделі (без пайплайнів)
            model = LogisticRegression(
                C=lr,              # тут використовуємо lr як C
                max_iter=ep,
                solver="lbfgs",
                multi_class="auto",
                random_state=42
            )
            model.fit(X_train, y_train)

            # Прогнози
            y_pred = model.predict(X_test)
            y_proba = model.predict_proba(X_test)

            # Метрики
            acc = accuracy_score(y_test, y_pred)
            loss = log_loss(y_test, y_proba)

            # Логування метрик у MLflow
            mlflow.log_metric("accuracy", acc)
            mlflow.log_metric("loss", loss)
            mlflow.log_metric("data", 10000)

            # Відправка метрик у Pushgateway — рівно як у тебе
            push_to_prometheus(acc, loss, f"iris_training_{timestamp}")

            print(f"   📊 accuracy={acc:.4f} | log_loss={loss:.4f}")

            # Апдейт найкращої моделі
            if acc > best_acc:
                best_acc = acc
                best_model = model
                best_params = {"learning_rate_as_C": lr, "epochs": ep}

# Збереження найкращої моделі локально
if best_model is None:
    raise RuntimeError("Не знайдено жодної валідної моделі під час перебору гіперпараметрів.")

save_dir = "./experiments/best_model"
os.makedirs(save_dir, exist_ok=True)
model_path = os.path.join(save_dir, "model.joblib")
joblib.dump(best_model, model_path)

print("✅ Експеримент завершено.")
print(f"📊 Найкраща точність: {best_acc:.4f}")
print(f"🧪 Найкращі параметри: {best_params}")
print(f"💾 Модель збережена: {model_path}")