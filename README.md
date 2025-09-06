README.md  # Ozirus's Dilemma: Predict # Ozirus's Dilemma: Predict # Ozirus's Dilemma: Predict # Ozirus's Dilemma: Predict # Ozirus's Dilemma: Predict -> Decide -> Prove

![Ozirus's Dilemma](https://img.shields.io/badge/Ozirus's_Dilemma-Predict_->_Decide_->_Prove-blue)
[![License](https://img.shields.io/badge/License-Apache_2.0-green.svg)](https://opensource.org/licenses/Apache-2.0)
[![Docs](https://img.shields.io/badge/Docs-CC--BY--4.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

This repository contains the reference implementation and documentation for **Ozirus's Dilemma**, a framework for making high-stakes decisions under uncertainty.

## Core Identity

Ozirus's Dilemma provides a structured, auditable, and mathematically grounded method to transform real-time data into decisive, provable actions. It consists of a three-part process:

1.  **Predict**: A **Structured Decision Arena (SDA)** uses event data to model near-term hazard and risk. It predicts the probability of future events using a Hawkes process.
2.  **Decide**: The SDA then solves a convex optimization problem to allocate a finite budget of resources (e.g., time, personnel) across a set of possible actions, balancing impact and cost.
3.  **Prove**: The resulting decision is compressed by a **Policy Computation Plane (PCP)** and cryptographically sealed by a **Receipt Generation Module (RGM)**. This produces a tamper-proof, signed receipt that can be shared with auditors and stakeholders as proof of a rigorous decision-making process.

The core mathematical identity of the framework is:
> OD = (Sig ◦ Merkle) ◦ (CRT ◦ Round) ◦ (Alloc ◦ Hazard ◦ Intensity)

This repository provides:
*   **Full Documentation**: Detailed explanation of the architecture, mathematical foundations, and algorithms.
*   **Python Implementation**: A modular `src` library implementing the core logic.
*   **Use-Case Examples**: Practical examples from Cybersecurity and Healthcare showing how to apply the framework.
*   **API Specification**: An OpenAPI definition for integrating Ozirus's Dilemma into other systems.

## Getting Started

To get started, explore the detailed documentation:

- **[Architecture](./docs/Architecture.md)**: A high-level overview of the system.
- **[Mathematical Foundations](./docs/Mathematical_Foundations.md)**: The core equations and theory.
- **[Use Cases](./docs/Use_Cases/)**: Real-world examples.

To run the examples, clone the repository and install the dependencies:
```bash
git clone https://github.com/your-org/ozirus-dilemma.git
cd ozirus-dilemma
pip install -r requirements.txt

# Run a simulation
python examples/cybersecurity_simulation.py
```

## License

The source code in this repository is licensed under the **Apache 2.0 License**.
The documentation is licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**.
[![Docs Links](https://img.shields.io/badge/docs_links-checks)](#)
