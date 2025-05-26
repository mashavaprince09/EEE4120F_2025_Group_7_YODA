# **Edge Detection System (Sobel Filter with Median Preprocessing)**  

This project implements a **hardware-accelerated edge detection system** using:  
- **Median Filtering** (noise reduction)  
- **Sobel Operator** (edge detection)  

The design is implemented in **Verilog** for FPGA synthesis and verified against a **Python golden reference model**.  

---

## **Features**  
### **1. Median Filter (Noise Reduction)**  
- Removes salt-and-pepper noise.  
- Processes a **3x3 window**, replacing each pixel with the median value.  
- **Edge pixels** are left unchanged.  

### **2. Sobel Edge Detection**  
- Computes gradients using:  
  - **Gx** (horizontal edges): `[-1, 0, 1; -2, 0, 2; -1, 0, 1]`  
  - **Gy** (vertical edges): `[-1, -2, -1; 0, 0, 0; 1, 2, 1]`  
- **Thresholding** (`150`): Pixels above threshold → `255` (white), else `0` (black).  

### **3. Verilog Implementation**  
- **Pipelined processing** (optimized for FPGA).  
- **Serial output** (pixel-by-pixel).  
- **Timing metrics**:  
  - `Critical Time` (hardware processing time).  
  - `Total Time` (including I/O overhead).  

### **4. Python Golden Model**  
- **Reference implementation** for verification.  
- Supports:  
  - **Raw Sobel** (`mode=0`).  
  - **Median + Sobel** (`mode=1`).  

---

## **Usage**  
### **1. Verilog Simulation (iverilog/ModelSim)**  
```bash
iverilog -o sim boo.v tb.v  
vvp sim  
```
**Output:**  
- `out/sobel.hex` (processed image).  
- Simulation timing metrics in console.  

### **2. Python Verification**  
```bash
python goldenMeasure.py img/image.hex  
```
**Options:**  
- `0` → Sobel only.  
- `1` → Median + Sobel.  

**Output:**  
- `out/goldenOutput.png` (visual result).  
- `out/golden_sobel.hex` (reference .hex file).  

---

## **Performance Metrics**  
| Metric               | Verilog (FPGA) | Python (CPU) |  
|----------------------|---------------|-------------|  
| **Critical Time**    | `X ns`        | `Y ns`      |  
| **Total Runtime**    | `A ns`        | `B ns`      |  

*(Example: FPGA achieves **10× speedup** over CPU.)*  

---

## **Dependencies**  
- **Verilog**:  
  - `iverilog` (simulation).  
  - FPGA tools (Xilinx/Intel Quartus for synthesis).  
- **Python**:  
  - `numpy`, `matplotlib`.  

---

## **Notes**  
- **Input format**: `.hex` (8-bit grayscale, 512×512).  
- **Tested with**:  
  - `img/mage.hex` (sample input).  
- **Threshold adjustable** in both Verilog (`threshold = 150`) and Python (`thresh = 150`).  

---

## **License**  
MIT License.  

--- 

**Key Improvement Areas**  
- Optimize Verilog for **lower latency**.  
- Add **real-time video input** support.  
- Compare against **other edge detectors** (Canny, Prewitt).  
