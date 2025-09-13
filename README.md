# Labyrinth Of Legendary Loot for AuroraOS
Original game you can find on [dominaxis-games.itch.io](https://dominaxis-games.itch.io/labyrinth-of-legendary-loot)

Labyrinth of Legendary Loot is a simple turn-based roguelike dungeon crawler focused on tactical combat. Every room is almost like a puzzle as you try to figure out the best way to defeat all enemies without taking too much damage.

# About port for AuroraOS
Game based on [LÖVE (Love2D) Engine](https://www.love2d.org/). Port of Love2D and port of this game made by sashikknox. You can [donate to sashikknox on boosty](https://boosty.to/sashikknox/single-payment/donation/380527/target?share=target_link).  
If you want to port your own game to AuroraOS, you can use [this tempate project](https://github.com/savegame/aurora-love2d).
If you know other cool open-source Love2D games, you can write to sashikknox's Telegram channel "[sashikknox Все портит!](https://t.me/auroraosgames)", and the game may be ported to AuroraOS!


# Build 
- download and install [AuroraSDK](https://developer.auroraos.ru/doc/software_development/sdk/downloads)
- list avaliable targets (use sfdk tool from SDK)
    ```
    ~/AuroraOS/bin/sfdk engine exec sb2-config -l
    ```
    its show something like
    ```
    AuroraOS-5.1.3.85-MB2-aarch64.default
    AuroraOS-5.1.3.85-MB2-aarch64
    AuroraOS-5.1.3.85-MB2-armv7hl.default
    AuroraOS-5.1.3.85-MB2-armv7hl
    AuroraOS-5.1.3.85-MB2-x86_64.default
    AuroraOS-5.1.3.85-MB2-x86_64
    ```
    where target names with `.default` suffixes - its snapshots. 
- Choose target "AuroraOS-5.1.3.85-MB2-aarch64" and build an RPM
    ```
    ~/AuroraOS/bin/sfdk -c "target=AuroraOS-5.1.3.85-MB2-aarch64" build-init
    ~/AuroraOS/bin/sfdk -c "target=AuroraOS-5.1.3.85-MB2-aarch64" prepare
    ~/AuroraOS/bin/sfdk -c "target=AuroraOS-5.1.3.85-MB2-aarch64" build
    ```
