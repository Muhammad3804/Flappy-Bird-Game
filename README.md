# Flappy Bird (Assembly)

🐦 **Flappy Bird** is a **console-based game written in Assembly language**, featuring **gravity-based movement, obstacle dodging, scoring, and a pause system**. This project is designed for beginners to understand **low-level game mechanics** using Assembly.

## 🌟 Features

- 🎮 **Flappy Bird Mechanics** – Fly and navigate through moving pipes
- 🏆 **Scoring System** – Earn points by passing obstacles
- 🛑 **Pause & Resume** – Pause anytime with `P`
- ⚡ **Real-time Gravity & Collision Detection**
- 🔄 **Smooth Game Flow** *(Note: Screen recording may show stuttering, but the actual game runs smoothly.)*

## 🎮 Controls

- **Press** **`Space`** – Flappy jumps
- **Press** **`P`** – Pause/Resume the game
- **Press** **`G`** – Quit the game

## 🛠️ Technologies Used

- **Assembly (x86, 16-bit NASM)**
- **BIOS Interrupts** – For keyboard input and display
- **Direct Memory Access** – For game rendering

## 📂 Project Structure

```
FlappyBirdGame/
│── FlappyBird.asm  # Main source code
│── README.md       # Project documentation
```

## 🚀 How to Run

### **Using DOSBox + NASM (Windows/Linux)**

1. Install **NASM** and **DOSBox**.
2. Assemble the program:
   ```sh
   nasm FlappyBird.asm -o FlappyBird.com
   ```
3. Run it in DOSBox:
   ```sh
   FlappyBird.com
   ```

## 📜 License

This project is for educational purposes only. Feel free to modify and improve it!

---

📌 **Note:** If you record the gameplay, the screen recording may show stuttering, but the actual game runs smoothly without any lag.


