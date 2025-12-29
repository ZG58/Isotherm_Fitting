---

# Isotherm Parameters Fitting & Aspen Mapping Guide

# 吸附等温线参数拟合与 Aspen 对接说明

## 1. 概述 (Overview)

本项目用于对吸附剂的平衡吸附数据进行拟合。拟合程序基于 **mmol/g**（即 **mol/kg**）量级的数据进行计算。

由此得到的参数 (a, b, c, d) 旨在直接对应 Aspen Adsorption 模型中的等温线参数 (IP_1, IP_2, IP_3, IP_4)。

## 2. 参数映射关系 (Parameter Mapping)

拟合得到的参数与 Aspen Adsorption 中 `Isotherms` 选项卡下的 `IP` 参数对应关系如下：

| 拟合参数 (Code) | Aspen 参数 (IP) | 物理含义 (示例) | 设定单位 (Target Unit) |
| --- | --- | --- | --- |
| **a** | **IP1** | 吸附常数指前因子 / Henry系数 | **mol · kg⁻¹ · bar⁻¹** |
| **b** | **IP2** | 温度依赖项 / 吸附热相关 | **K** |
| **c** | **IP3** | 平衡常数指前因子 | **bar⁻¹** |
| **d** | **IP4** | 温度依赖项 | **K** |

> **注意**：上述 mapping 假设使用了包含温度依赖项的 Langmuir 或类似形式的方程（如  ...）。请确保 Aspen 中选择的模型形式与代码拟合公式一致。

## 3. 单位一致性与换算警告 (Critical Unit Warning)

### 3.1 数据源单位

* 本项目拟合所用的原始实验数据单位为：**mmol/g**。
* 换算关系：。
* 因此，拟合得到的参数 **a (IP1)** 的数值也是基于 **mol/kg** 量级的。

### 3.2 Aspen Adsorption 的默认单位陷阱

Aspen Adsorption 系统默认（Default）的质量单位通常为 **kmol/kg** (即 **mol/g**)。

* **拟合单位**: mol/kg
* **Aspen 默认**: kmol/kg
* **倍率关系**: 

### 3.3 如何在 Aspen 中输入 (Action Required)

为了防止 1000 倍的模拟误差，在将参数输入 Aspen 时，请务必执行以下 **二选一** 的操作：

#### 方案 A：修改 Aspen 单位设置（推荐）

在 Aspen Adsorption 的 `Isotherms` 输入界面中，点击单位下拉菜单：

1. 将 IP1 的单位从默认的 `kmol/(kg.bar)` 手动更改为 **`mol/(kg.bar)`**。
2. 此时，直接将拟合得到的  值填入即可，**无需手动换算**。

#### 方案 B：手动换算数值

如果您保持 Aspen 的默认单位 `kmol/(kg.bar)` 不变，则必须对参数  进行换算：

$$ IP_1 (Aspen) = \frac{a (Fitted)}{1000} $$
* *例如：拟合得到  (mol/kg/bar)，输入 Aspen 时填  (kmol/kg/bar)。*

*Last Updated: 2025-12-29*