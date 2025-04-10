import os
import torch
import torch.distributed as dist
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torch.utils.data import DataLoader, DistributedSampler
from torchvision import datasets, transforms

class Net(nn.Module):
    def __init__(self):
        super().__init__()
        self.conv = nn.Sequential(
            nn.Conv2d(1, 20, 5, 1), nn.ReLU(), nn.MaxPool2d(2),
            nn.Conv2d(20, 50, 5, 1), nn.ReLU(), nn.MaxPool2d(2)
        )
        self.fc = nn.Sequential(
            nn.Linear(4 * 4 * 50, 500), nn.ReLU(),
            nn.Linear(500, 10)
        )

    def forward(self, x):
        x = self.conv(x)
        x = x.view(-1, 4 * 4 * 50)
        return F.log_softmax(self.fc(x), dim=1)

def train(model, device, loader, optimizer, epoch, rank):
    model.train()
    total_loss = 0
    for data, target in loader:
        data, target = data.to(device), target.to(device)
        optimizer.zero_grad()
        loss = F.nll_loss(model(data), target)
        loss.backward()
        optimizer.step()
        total_loss += loss.item()
    avg_loss = total_loss / len(loader)
    print(f"[Epoch {epoch}] Rank {rank}: Avg Loss {avg_loss:.4f}")

def test(model, device, loader, epoch, rank):
    model.eval()
    correct, total = 0, 0
    with torch.no_grad():
        for data, target in loader:
            data, target = data.to(device), target.to(device)
            pred = model(data).argmax(dim=1)
            correct += pred.eq(target).sum().item()
            total += data.size(0)
    accuracy = correct / total
    print(f"[Epoch {epoch}] Rank {rank}: Accuracy {accuracy:.2%}")

def main():
    rank = int(os.environ.get("SING_RANK", 0))
    world_size = int(os.environ.get("SING_WORLD_SIZE", 1))
    master_addr = os.environ.get("SING_MASTER_ADDR", "localhost")
    ################################⬇⬇⬇ Modify Here ⬇⬇⬇################################
    os.environ.update({                   # Customize your own environment variables name for distributed training
        "RANK": str(rank),                # modify "Rank" to "YOUR_OWN_RANK"
        "WORLD_SIZE": str(world_size),    # modify "WORLD_SIZE" to "YOUR_OWN_WORLD_SIZE"
        "MASTER_ADDR": master_addr,       # modify "MASTER_ADDR" to "YOUR_OWN_MASTER_ADDR"
        "MASTER_PORT": "1234"             # modify "MASTER_PORT" to "YOUR_OWN_MASTER_PORT" and the port you want to use
    })
    ################################⬆⬆⬆ Modify Here ⬆⬆⬆################################
    dist.init_process_group("nccl")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = nn.parallel.DistributedDataParallel(Net().to(device), device_ids=[device.index] if device.type == "cuda" else None)

    transform = transforms.ToTensor()
    train_ds = datasets.FashionMNIST("./data", train=True, download=True, transform=transform)
    test_ds = datasets.FashionMNIST("./data", train=False, download=True, transform=transform)
    train_loader = DataLoader(train_ds, batch_size=64, sampler=DistributedSampler(train_ds))
    test_loader = DataLoader(test_ds, batch_size=1000, sampler=DistributedSampler(test_ds))

    optimizer = optim.SGD(model.parameters(), lr=0.01, momentum=0.5)

    for epoch in range(1, 6):
        train_loader.sampler.set_epoch(epoch)
        train(model, device, train_loader, optimizer, epoch, rank)
        # test(model, device, test_loader, epoch, rank)

    if rank == 0:
        torch.save(model.state_dict(), "ddp_model.pt")

    dist.destroy_process_group()
    print(f"Rank {rank}: Training completed.")

if __name__ == "__main__":
    main()