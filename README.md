# 📡 Cellular Signal Mapper Pro

**Turn your Android phone into a professional network diagnostics tool!**

Built entirely in Termux with bash scripting. No fancy equipment needed - just your phone and this script.

## 🚀 Features

- **Real-time signal monitoring** (-dBm values)
- **GPS-integrated coverage mapping**
- **Automated CSV data logging**
- **Live statistics dashboard**
- **Signal quality classification** (Excellent → No Signal)
- **Professional animations & UI**

## 🛠️ Installation

```bash
# Install requirements
pkg install termux-api jq

# Clone the repo  
git clone https://github.com/ibrahimu8/cellular-signal-mapper.git
cd cellular-signal-mapper

# Make it executable
chmod +x signal_mapper_pro.sh

# Run it!
./signal_mapper_pro.sh
