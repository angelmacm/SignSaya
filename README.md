# SignSaya
A system capable of interpreting these hand signals with Filipino Sign Language by providing technological solution that is specifically tailored to address frequently asked question for deaf tourists to enhance inclusivity through a multilingual feature.

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Architechture](#architecture)

## Introduction

This project presents a system utilizing Tensorflow-lite to interpret Filipino Sign Language (FSL) hand signals. Designed to address frequently asked questions for deaf tourists, the system provides a technological solution tailored to enhance inclusivity. By integrating multilingual features, it aims to bridge communication gaps and promote a more inclusive environment for deaf individuals.

## Installation

Follow these steps to set up the project locally:
### 1. Make sure that you have [Flutter](https://docs.flutter.dev/get-started/install "Flutter Installation Page") and [Android Studio](https://docs.flutter.dev/get-started/install "Android Studio Download Page") installed in your device
### 2. Clone the Repository
```bash
# Clone the repository
git clone https://github.com/angelmacm/SignSaya.git

# Navigate to the project directory
cd SignSaya

```
### 3. Navigate to `software/Signsaya/signsaya` and run `flutter pub get`

## Architecture

The system architecture comprises the following components:

1. **Data Collection**: Collection of FSL hand signals using a ICM-20948 and DIY bend sensor composed of velostat, electric tape, and conductive fabric.
2. **Preprocessing**: Normalization of time-series data and forward filling of discrepancies in data count.
3. **Model Training**: Training a optimized Tensorflow Lite model using a dataset of FSL hand signals.
4. **Model Deployment**: Deploying the trained model on an edge device.
5. **Inference Engine**: The Tensorflow Lite model interprets the hand signals in real-time.
6. **Multilingual Feature**: Provides translations and answers frequently asked questions for deaf tourists in multiple languages.
7. **Speech to Text Feature**: Accesible 2-way communication for non-sign language indivdual
