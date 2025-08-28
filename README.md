# mlops

Repository for managing MLOps processes associated with deploying machine learning models.

# EKS VPC Cluster Infrastructure

Terraform Infrastructure as Code для розгортання VPC та Kubernetes кластера в AWS.

Опис проекту
Цей проект містить модульну Terraform конфігурацію для автоматичного розгортання повноцінної інфраструктури AWS, що включає:

VPC - віртуальна приватна мережа з публічними та приватними підмережами

EKS Cluster - Kubernetes кластер з двома CPU нод-пулами.

# Запуск проекту

## 1. Ініціалізація Terraform

```
terraform init
```

## 2. Перегляд майбутніх змін

```
terraform plan
```

## 3. Розгортання інфраструктури

```
terraform apply
```

## . Налаштування kubectl

```
aws eks update-kubeconfig --region us-east-1 --name goit-mlops-eks-cluster
```

## 5. Перевірка кластера

```
kubectl get nodes
kubectl get pods --all-namespaces
```

# Модулі

## VPC Модуль

Створює VPC з публічними та приватними підмережами
Налаштовує Internet Gateway та NAT Gateway
Конфігурує маршрутизацію та Security Groups

## EKS Модуль

Розгортає EKS Control Plane
Створює CPU нод-пули
Налаштовує RBAC та доступи
Встановлює необхідні add-ons

## Очищення ресурсів

```bash
terraform destroy
```
