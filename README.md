---

# 吸附等温线拟合工具 (Isotherm Fitting Tool)

本项目用于根据实验测定的吸附数据（Loading vs Pressure at different Temperatures），拟合生成 Aspen Adsorption 所需的等温线模型参数。

主要功能包括：

1. 自动读取 `.mat` 格式的实验数据。
2. 使用多种模型（Extended Langmuir 2, Extended Langmuir 3, Dual-site Langmuir）进行非线性回归拟合。
3. 生成对比图表和参数 CSV 文件。
4. **输出直接对应 Aspen Adsorption 模拟所需的 IP 参数。**

## 1. 参数映射与单位说明 (关键)

本项目中的拟合数据基于 **mmol/g**，在数值上等同于 **mol/kg**。
Aspen Adsorption 中的 **Extended Langmuir 2** 模型通常使用 IP_1 到 IP_4 四个参数。

### 1.1 模型公式对应

MATLAB 代码 (`src/define_models.m`) 中使用的 **EX-L 2** 模型公式如下：
$$q = \frac{a \cdot e^{\frac{b}{T}} \cdot P}{1 + c \cdot e^{\frac{d}{T}} \cdot P}$$

Aspen Adsorption 中的标准 Extended Langmuir 2 公式通常表示为：
$$q = \frac{IP_1 \cdot e^{\frac{IP_2}{T}} \cdot P}{1 + IP_3 \cdot e^{\frac{IP_4}{T}} \cdot P}$$

### 1.2 参数映射表

拟合结果文件（`results/xxx/xxx_EXL2_params.csv`）中的  与 Aspen 参数一一对应：

| MATLAB 参数 | Aspen 参数 | 物理含义 | 拟合结果单位 (本项目) | Aspen 单位 (需注意) |
| --- | --- | --- | --- | --- |
| **a** | **IP1** | 吸附指前因子 | $$mol \cdot kg^{-1} \cdot bar^{-1}$$ | $$kmol \cdot kg^{-1} \cdot bar^{-1}$$  |
| **b** | **IP2** | 吸附热相关项 | $$K$$ | $$K$$ |
| **c** | **IP3** | 吸附平衡常数指前因子 | $$bar^{-1}$$ | $$bar^{-1}$$ |
| **d** | **IP4** | 吸附热相关项 | $$K$$ | $$K$$ |

### 1.3 ⚠️ 关于单位的重要警告 (Aspen Unit Conversion)

**请务必检查你的 Aspen Adsorption 模拟设置：**

1. **本项目输出单位**：
* 吸附量 :  mol/kg
* 压力 : bar
* 温度 : K
* 因此，参数 **a (IP1)** 的单位是 $$mol \cdot kg^{-1} \cdot bar^{-1}$$。


2. **Aspen Adsorption 默认设置**：
* Aspen 的默认单位集（SI）中，吸附量通常是 **kmol/kg** 。
* 压力通常是bar。


3. **如何输入到 Aspen**：
* **方法：手动换算**
如果保持 Aspen 默认的 **** 单位，你需要将 CSV 文件中的  值除以 1000 后再输入到 。

$$IP_1 (Aspen输入值) = \frac{a (MATLAB拟合值)}{1000}$$



---

## 2. 项目文件结构

```text
Isotherm_Fitting/
├── data/                   # 存放实验数据 (.mat)
│   ├── NaY_CO2.mat         # 示例：CO2 在 NaY 上的吸附数据
│   └── ...
├── src/                    # 源代码核心库
│   ├── define_models.m     # 定义拟合模型公式 (EXL2, EXL3, Dual)
│   └── load_data.m         # 数据读取脚本
├── results/                # 输出结果 (自动生成)
│   └── [Dataset_Name]/     # 按数据集名称分类
│       ├── *_fit.png       # 拟合效果图
│       ├── *_params.csv    # 拟合参数表 (含 a,b,c,d)
│       └── *_Model_Comparison.csv # 各模型 R2/AIC 对比
├── main.m                  # 【主程序】运行此文件开始拟合
├── plot_isotherms.m        # 验证脚本：读取参数并绘制等温线进行回验
└── README.md               # 说明文档

```

## 3. 如何运行

1. **准备数据**：
* 确保你的实验数据已保存为 `.mat` 格式。
* 数据矩阵需包含 3 列：`[Temperature(K), Pressure(bar), Loading(mmol/g)]`。
* 将 `.mat` 文件放入 `data/` 文件夹。


2. **配置主程序**：
* 打开 `main.m`。
* 修改 `data_file` 变量指向你的数据文件名，例如：
```matlab
data_file = fullfile('data', 'NaY_CO.mat');

```


* (可选) 调整 `config.algorithm` 或 `config.retry_count` 以获得更好的拟合效果。


3. **运行拟合**：
* 在 MATLAB 中运行 `main.m`。
* 程序会自动在 `results/` 下创建对应的文件夹，并保存图片和 CSV 参数文件。


4. **结果分析**：
* 打开 `results/xxx/xxx_Model_Comparison.csv` 查看哪个模型效果最好（R_Square 越接近 1，AIC 越低越好）。
* 打开对应的 `xxx_params.csv` 获取 a, b, c, d 参数。



## 4. 模型说明

* **EX-L 2 (Extended Langmuir 2)**:
* 最常用的 Aspen 模型，适用于大多数物理吸附。
* 对应参数： a, b, c, d-> IP_1, IP_2, IP_3, IP_4。


* **EX-L 3**:
* 包含温度相关的饱和吸附量项 (a - bT) 。
* **注意**：此模型参数不能直接对应标准的 Aspen Extended Langmuir 2，通常用于自定义模型或分析饱和吸附量的变化。


* **Dual-site (双位点)**:
* 假设存在两类不同的吸附位点。
* 公式为两个 Langmuir 项之和。在 Aspen 中使用该模型需要选择 "Dual Site Langmuir" 对应的等温线类型。



## 5. 环境要求

* MATLAB R2018b 或更高版本
* Curve Fitting Toolbox (曲线拟合工具箱)