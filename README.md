# CamGuide App Overview

## Award
CamGuide was selected as a Winner in the Swift Student Challenge 2025.

## App Features
- The app uses Apple’s Vision framework, specifically the `CalculateImageAestheticsScoresRequest`, to evaluate the aesthetics score of the camera’s live preview in real time.
- Based on the scores, CamGuide provides on-screen guidance to help users compose better photos.

## How It Works
- The screen is divided into a 3×3 grid (nine regions), and an aesthetics score is calculated for each region using the `regionCoords` property in the `CameraViewModel`.
- The app identifies which region has the highest score and guides the user so that this high-scoring region is positioned at the center of the frame.
- This makes it easy for anyone to capture well-composed photos by simply following the intuitive guidance.
