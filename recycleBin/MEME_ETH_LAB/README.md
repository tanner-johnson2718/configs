# MEME Layer 1 and 2 Ethernet Lab

In this installment of the MEME series we take more of a lab homework assignment approach. The aim is to dig deeply into Layer 1 and 2 (in the OSI model) of the Ethernet standard. The approach is from a low-level / embedded / firmware software perspective. The idea is to take your everyday linux laptop, an RPI and look into the specifics of link set up, ethernet frame layout, how drivers set up the network hardware, low level networking protocols (L1 and L2), etc. Since this is such a vast topic we will narrow the scope with the following constraints:

* The main interface will be a linux system on both the laptop and RPI side.
* Will build a minimal rpi image to flash using buildroot
* Laptop will be our everyday laptop running ubuntu
* Kernel hacking will happen on RPI only
* Will simply connect an etherner cord from RPI to build PC.
* Will use UART GPIO pins on PI for interface
* Will restrict to Layer 1 and 2 i.e. no IP, TCP, etc.

Some defining goals to get the project going and figure out a starting point are the following:

* Understand MAC and PHY Hardware
* Understand Speed Negotiation
* Layer 1 and 2 Protocols
* MDIO and MII
* Initial handshake and negotiation
* Neighbor Discovery (0xFF)
* Ring Buffer on NIC
* How do frames make their way to user-space
* Catalog important Linux commands
* Use and read Official IEEE standards

# Part 1 Hardware and Init Software set up

* [X] [P1.1](./P1.1/) - Create a Raw Socket Example Program
* [X] [P1.2](./P1.2/) - Use BuildRoot to build and make loadable image for the RPI
    * [X] Connect to RPI via UART terminal
    * [X] Develop means of pushing code to RPI
        * [X] Develop a means of cross compiling
    * [X] Connect GDB debugger to rpi over UART.
    * [X] Send and Recv a Raw Eth Frame from RPI to Laptop
    * [X] [SW Flow and How to use scripts](./P1.2/README.md#sw-flow)

# Part 2 RPI MAC and PHY Drivers

* [X] [P2.1](./P2.1/) - Use sysfs kernel interface to play with NIC interface
* [X] [P2.2](./P2.2/) - Break into phy driver code
    * [X] Refactor code
    * [X] MDIO bus
    * [X] KDB
    * [X] BCM54213PE Driver 
* [X] [P2.3](./P2.3/) Reverse Engineer the BCM 2711 genet driver