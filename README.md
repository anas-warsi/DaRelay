# 🚀 DaRelay – Offline Mesh Communication App

> **“When the internet fails, communication should not.”**

DaRelay is a decentralized mobile application that enables seamless communication **without internet** by forming a **peer-to-peer mesh network** using nearby devices.

---

## 📌 Overview

In critical situations like natural disasters, remote areas, or network outages, communication becomes impossible due to lack of internet.

DaRelay solves this by enabling **offline, device-to-device communication**, where messages travel across multiple devices using a **multi-hop relay system**.

---

## 📱 Problem Statement

- 🌐 Internet dependency causes communication failure  
- 🚫 No connectivity in rural or disaster-hit areas  
- 📉 Network congestion during emergencies  

---

## 💡 Solution

DaRelay introduces a **decentralized mesh network** where:

- Devices connect directly (no internet required)
- Messages hop across multiple devices
- Communication works even without direct connection
## 🧠 Core Concepts

- 📡 Peer-to-Peer (P2P) Communication  
- 🌐 Decentralized Networking  
- 🔁 Multi-hop Message Relay  

---

## ✨ Features

- 📡 Discover nearby devices  
- 🔗 Connect without internet  
- 💬 Real-time messaging  
- 🔁 Automatic message relay  
- 📶 Fully offline functionality  
- ⚡ Lightweight & fast  

---

## 🏗️ Architecture

DaRelay follows a modular architecture:

### 🟢 UI Layer
- Chat Interface  
- Device Discovery Screen  

### 🟢 Networking Layer
- WiFi Direct / Bluetooth communication  
- Socket-based messaging  

### 🟢 Logic Layer
- Message processing  
- Relay algorithm

- 
---

## ⚙️ Tech Stack

- Flutter – UI Development  
- Dart – Programming Language  
- WiFi Direct / Bluetooth – Device communication  
- Socket Programming – Real-time messaging
- ## 🔥 Core Logic – Relay System

Each device acts as a node in the network.

If a message is not meant for the current device, it is automatically forwarded:

```dart
if (message.receiver != myDeviceId) {
  forwardToNearbyDevices(message);
}
