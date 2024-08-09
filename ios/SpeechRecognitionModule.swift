//
//  SpeechRecognitionModule.swift
//  MyNativeModule
//
//  Created by Kumar Aman on 08/08/24.
//

// SpeechRecognitionModule.swift

import Foundation
import Speech
import React

@objc(SpeechRecognitionModule)
class SpeechRecognitionModule: RCTEventEmitter {
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var hasListeners = false
    
    private var transcribedWords: [String] = []
    private var isPaused = false
    private var isWaitingForKeyword = false
    private var lastProcessedText = ""
    
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    override func supportedEvents() -> [String]! {
        return ["onSpeechRecognized", "onLogMessage", "onStateChange"]
    }
    
    override func startObserving() {
        hasListeners = true
    }
    
    override func stopObserving() {
        hasListeners = false
    }
    
    private func sendLog(_ message: String) {
        if hasListeners {
            sendEvent(withName: "onLogMessage", body: ["message": message])
        }
        print("SpeechRecognitionModule: \(message)")
    }
    
    private func sendStateChange() {
        if hasListeners {
            sendEvent(withName: "onStateChange", body: ["isPaused": isPaused, "isWaitingForKeyword": isWaitingForKeyword])
        }
    }
    
    @objc
    func startListening(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        guard !audioEngine.isRunning else {
            resolve(false)
            return
        }
        
        do {
            try startRecording()
            isPaused = false
            isWaitingForKeyword = false
            sendStateChange()
            sendLog("Started listening")
            resolve(true)
        } catch {
            reject("ERROR_SPEECH_RECOGNITION", "Failed to start speech recognition: \(error.localizedDescription)", error)
        }
    }
    
    @objc
    func stopListening(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            transcribedWords.removeAll()
            isPaused = false
            isWaitingForKeyword = false
            lastProcessedText = ""
            sendStateChange()
            sendLog("Stopped listening")
            resolve(true)
        } else {
            resolve(false)
        }
    }
    
    @objc
    func pauseListening(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        isPaused = true
        isWaitingForKeyword = true
        sendStateChange()
        sendLog("Paused listening. Waiting for 'mark' or 'marc'")
        resolve(true)
    }
    
    @objc
    func clearText(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        transcribedWords.removeAll()
        if hasListeners {
            sendEvent(withName: "onSpeechRecognized", body: ["text": ""])
        }
        sendLog("Cleared transcribed text")
        resolve(true)
    }
  
  @objc
  func resumeListening(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
      sendLog("Entering resumeListening")
      do {
          sendLog("Stopping current audio engine and recognition task")
          audioEngine.stop()
          recognitionRequest?.endAudio()
          recognitionTask?.cancel()
          
          // Add a small delay before restarting
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              do {
                  self.sendLog("Attempting to restart recording")
                  try self.startRecording()
                  
                  self.isPaused = false
                  self.isWaitingForKeyword = false
                  
                  self.sendLog("Sending state change")
                  self.sendStateChange()
                  self.sendLog("Resumed listening")
                  
                  if self.hasListeners {
                      self.sendLog("Sending current transcribed text")
                      self.sendEvent(withName: "onSpeechRecognized", body: ["text": self.transcribedWords.joined(separator: " ")])
                  }
                  
                  self.sendLog("resumeListening completed successfully")
                  resolve(true)
              } catch {
                  self.sendLog("Error in delayed restart: \(error.localizedDescription)")
                  reject("ERROR_RESUME_LISTENING", "Failed to resume speech recognition: \(error.localizedDescription)", error)
              }
          }
      } catch {
          sendLog("Error in resumeListening: \(error.localizedDescription)")
          reject("ERROR_RESUME_LISTENING", "Failed to resume speech recognition: \(error.localizedDescription)", error)
      }
  }

  private func startRecording() throws {
      sendLog("Entering startRecording")
      
      if let recognitionTask = recognitionTask {
          sendLog("Cancelling existing recognition task")
          recognitionTask.cancel()
          self.recognitionTask = nil
      }
      
      if audioEngine.isRunning {
          sendLog("Stopping running audio engine")
          audioEngine.stop()
      }
      
      sendLog("Removing existing tap on audio input node")
      audioEngine.inputNode.removeTap(onBus: 0)
      
      sendLog("Configuring audio session")
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
      
      sendLog("Creating new speech recognition request")
      recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
      
      guard let recognitionRequest = recognitionRequest else {
          let error = NSError(domain: "SpeechRecognitionErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
          sendLog("Failed to create recognition request")
          throw error
      }
      
      recognitionRequest.shouldReportPartialResults = true
      
      sendLog("Starting new recognition task")
      recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
          guard let self = self else { return }
          
          if let result = result {
              let transcribedText = result.bestTranscription.formattedString
              self.sendLog("Received transcription: \(transcribedText)")
              self.processRecognizedSpeech(transcribedText)
          }
          
          if let error = error {
              self.sendLog("Error in recognition task: \(error.localizedDescription)")
          }
          
          if error != nil || result?.isFinal == true {
              self.sendLog("Finalizing recognition task")
              self.audioEngine.stop()
              self.audioEngine.inputNode.removeTap(onBus: 0)
              self.recognitionRequest = nil
              self.recognitionTask = nil
              
              // Attempt to restart if not paused
              if !self.isPaused {
                  self.sendLog("Attempting to restart after finalization")
                  try? self.startRecording()
              }
          }
      }
      
      sendLog("Installing tap on audio input node")
      let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
      audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
          self.recognitionRequest?.append(buffer)
      }
      
      sendLog("Preparing audio engine")
      audioEngine.prepare()
      
      sendLog("Starting audio engine")
      try audioEngine.start()
      
      sendLog("startRecording completed successfully")
  }
    
  private func processRecognizedSpeech(_ text: String) {
      guard text != lastProcessedText else { return }
      lastProcessedText = text
      
      let words = text.components(separatedBy: .whitespacesAndNewlines)
      
      if isPaused {
          if isWaitingForKeyword {
              if words.contains("mark") || words.contains("marc") {
                  isWaitingForKeyword = false
                  sendStateChange()
                  sendLog("Keyword detected. Waiting for 'resume' or 'stop' command")
              }
          } else {
              if words.contains("resume") {
                  resumeListening({ _ in }, rejecter: { _, _, _ in })
              } else if words.contains("stop") {
                  stopListening({ _ in }, rejecter: { _, _, _ in })
              }
          }
      } else {
          if words.last == "pause" {
              pauseListening({ _ in }, rejecter: { _, _, _ in })
          } else {
              transcribedWords = words
              if hasListeners {
                  sendEvent(withName: "onSpeechRecognized", body: ["text": transcribedWords.joined(separator: " ")])
              }
          }
      }
  }
    
    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return false
    }
}
