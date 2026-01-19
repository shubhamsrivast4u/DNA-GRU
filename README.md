

# DNA-GRU: Efficient DNA Sequence Reconstruction with Compact Neural Networks

Official implementation of "Efficient DNA Sequence Reconstruction with DNA-GRU".


## Repository Structure

```
├── DNA-GRU_Erlich.ipynb                      # Training & evaluation on Erlich dataset
├── DNA-GRU_Grass.ipynb                       # Training & evaluation on Grass dataset
├── DNA-GRU_Srinivasavaradhan.ipynb           # Training & evaluation on Srinivasavaradhan dataset
├── DNAFormer_vs_DNA-GRU_parameter_analysis.ipynb  # Architectural comparison & complexity analysis
├── Synthetic_Data_Generator.ipynb            # Synthetic training data generation
└── README.md
```

## Notebooks Description

### Training & Evaluation Notebooks

- **`DNA-GRU_Erlich.ipynb`**: Complete pipeline for the Erlich et al. dataset (DNA Fountain, Illumina miSeq). Includes model training, evaluation, and failure rate calculation.

- **`DNA-GRU_Grass.ipynb`**: Training and evaluation on the Grass et al. dataset (CustomArray, Illumina miSeq) with Reed-Solomon coded sequences.

- **`DNA-GRU_Srinivasavaradhan.ipynb`**: Handles the challenging Srinivasavaradhan dataset (Twist, MinION) with high Nanopore indel rates.

### Analysis Notebooks

- **`DNAFormer_vs_DNA-GRU_parameter_analysis.ipynb`**: Comprehensive module-by-module comparison of DNAformer and DNA-GRU architectures, including parameter counts and FLOP analysis.

- **`Synthetic_Data_Generator.ipynb`**: Generates synthetic training data with realistic IDS error profiles, noise deviation, and false copy injection for robust model training.

## Requirements

```
torch>=2.0.0
numpy>=1.21.0
pandas>=1.3.0
tqdm>=4.62.0
matplotlib>=3.4.0
```

## Installation

```bash
git clone https://github.com/yourusername/DNA-GRU.git
cd DNA-GRU
pip install -r requirements.txt
```

## Usage

### Training

Open the appropriate notebook for your dataset and run all cells:

```python
# Example: Training on Erlich dataset
# See DNA-GRU_Erlich.ipynb for complete implementation
```

### Synthetic Data Generation

```python
# Generate training data with realistic error profiles
# See Synthetic_Data_Generator.ipynb for implementation
```

### Model Evaluation

Each training notebook includes evaluation code that computes:
- Cluster-level failure rates
- Per-position accuracy
- Reconstruction quality metrics

## Dataset Configurations

| Dataset | Label Length | Max Deviation | Sequencing Platform |
|---------|-------------|---------------|---------------------|
| Erlich | 152 | 10 | Illumina miSeq |
| Grass | 117 | 11 | Illumina miSeq |
| Srinivasavaradhan | 110 | 10 | MinION (Nanopore) |

## Citation

If you use this code in your research, please cite:

```bibtex
@article{dna-gru2025,
  title={Efficient DNA Sequence Reconstruction with DNA-GRU},
  author={Srivastava, Shubham and Benerjee, Krishna Gopal and Banerjee, Adrish},
  journal={},
  year={2025}
}
```

## Acknowledgments

We gratefully acknowledge the following resources that made this work possible:

- **[Deep-DNA-based-storage](https://github.com/itaiorr/Deep-DNA-based-storage)** by Bar-Lev et al. for the reference implementation, error statistics, and benchmark datasets. Their DNAformer architecture served as the foundation and inspiration for DNA-GRU.

- The original dataset creators:
  - Erlich & Zielinski (2017) - DNA Fountain
  - Grass et al. (2015) - Reed-Solomon coded DNA storage
  - Srinivasavaradhan et al. - Nanopore sequencing datasets

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For questions or collaborations, please contact:
- Shubham Srivastava - shubhsr@iitk.ac.in
- Krishna Gopal Benerjee - kgopal@iitk.ac.in
- Adrish Banerjee - adrish@iitk.ac.in

Department of Electrical Engineering, Indian Institute of Technology Kanpur, India
