# We need to use the nvcr.io/nvidia/pytorch image as a base image to support both linux/amd64 and linux_arm64 platforms.
# PyTorch=2.2.0, cuda=12.3.2
# Ref: https://docs.nvidia.com/deeplearning/frameworks/pytorch-release-notes/rel-24-01.html#rel-24-01
# FROM pytorch/pytorch:latest
FROM nvcr.io/nvidia/pytorch:24.01-py3

RUN apt-get update && apt-get install -y openssh-server

RUN pip install tensorboardX==2.6.2
#RUN apt install -y python3-pip
#RUN pip install torch --no-cache-dir
#RUN pip install torchvision

RUN echo 'root:****' | chpasswd

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

RUN mkdir /var/run/sshd

RUN mkdir -p /opt/mnist
WORKDIR /opt/mnist/src
ADD mnist.py /opt/mnist/src/mnist.py

RUN chgrp -R 0 /opt/mnist \
    && chmod -R g+rwX /opt/mnist

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]