# hw-10-prox

задание:
развертывание виртуальных машин на proxmox с помощью terraform

Цель:
terraform скрипты для развертывания виртуальных машин на проксмоксе

Сначала создаем на прокмокс хосте роль с ограниченными возможностями, затем сервисного юзера для работы провайдера и применяем эту роль к созданному юзеру

pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate SDN.Use Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt"

pveum user add terraform-prov@pve --password <password>

pveum aclmod / -user terraform-prov@pve -role TerraformProv

Далее нам нужно создать шаблоны на ноде, для этого скачиваем к себе во временное место облачные образы, например дебиан и убунту

wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

wget https://cloud.debian.org/images/cloud/bullseye/20231013-1532/debian-11-genericcloud-amd64-20231013-1532.qcow2

далее нам нужно подготовить образы, для этого ставим доп пакет:  apt update -y && apt install libguestfs-tools -y

и выполняем ряд действий: 
1. инсталируем гест-агент
virt-customize -a image-name.img/qcow2 --install qemu-guest-agent
2. добавляем юзера если нужно
virt-customize -a image-name.img/qcow2 --run-command 'useradd username'
3. создаем директорию юзера, куда положим его ссх ключ 
virt-customize -a image-name.img/qcow2 --run-command 'mkdir -p /home/username/.ssh'
4. импортируем ключ
virt-customize -a image-name.img/qcow2 --ssh-inject username:file:/home/username/.ssh/id_rsa.pub
5. меняем права на домашнюю директорию
virt-customize -a image-name.img/qcow2 --run-command 'chown -R username:username /home/username'

затем выполняем создание шаблонов на прокс ноде для обоих образов, меняя только id:
qm create 9500 --name "ub-2004-cloudinit-tpl" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9500 focal-server-cloudimg-amd64.img local-lvm
qm set 9500 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9500-disk-0
qm set 9500 --boot c --bootdisk scsi0
qm set 9500 --ide2 local-lvm:cloudinit
qm set 9500 --serial0 socket --vga serial0
qm set 9500 --agent enabled=1
qm template 9500

после этого скачиваем проект на машину с которой будем доплоить виртуалки

git clone https://github.com/alexeykazancev/hw-10-prox.git

переходим в папку проекта, там есть файл terraform.tfvars.example , переименовываем его в terraform.tfvars меняем внутри значения переменных на свои

запускаем инициализацию провайдера
terraform init
далее смотрим , что у нас создастся
terraform plan
и запускаем деплой
terraform apply