# OpenStack-Wallaby
Installation Script for OpenStack Stein based on ARM Server (`ubuntu20.04`)


</br>
 
## OpenStack installer

ARM CPU Server-based Stein version manual installation method is written on [Wiki](https://github.com/shhan0226/Project-OpenStack/wiki).

Here, a shell script is written based on the contents of the [Wiki](https://github.com/shhan0226/Project-OpenStack/wiki), and the execution order of the shell script is as follows.

### Downloads
```bash
# sudo su
# cd
# git clone https://github.com/shhan0226/OpenStack-Wallaby.git
```

### Step.1 Prerequisites
- It runs on the Controller Node.
  ```
  # cd
  # ./OpenStack-Wallaby/init.sh
  ```

- It runs on the Controller Node.
  ```
  # cd 
  # ./OpenStack-Wallaby/init.sh
  ```

### Step.2 Keystone
- It runs on the Controller Node.
  ```
  # ./OpenStack-Wallaby/keystone.sh
  ```

### Step.3 Glance
- It runs on the Controller Node.
  ```
  # ./OpenStack-Wallaby/glance.sh
  ```

### Step.4 Placement
- It runs on the Controller Node.
  ```
  # ./OpenStack-Wallaby/placement.sh
  ```

### Step.5 Nova
- It runs on the Controller Node.
  ```
  # ./OpenStack-Wallaby/nova-controller.sh
  ```

- It runs on the compute Node.
  ```
  # ./OpenStack-Wallaby/nova-compute.sh
  ```

- It runs on the Controller Node.
  ```
  # ./OpenStack-Wallaby/nova-check-to-compute.sh
  ```

### Step.6 Neutron
- It runs on the Controller Node.
  ```
  # ./OpenStack-Wallaby/neutron-controller.sh
  ```

- It runs on the compute Node.
  ```
  # ./OpenStack-Wallaby/neutron-compute.sh
  ```

### Setp.7 Horizon
- It runs on the Controller Node.
  ```
  # ./OpenStack-Wallaby/horizon.sh
  ```

