/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, { useState, useEffect, useRef } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, NativeModules, NativeEventEmitter, Animated, ScrollView } from 'react-native';

const { SpeechRecognitionModule } = NativeModules;
const speechRecognitionEmitter = new NativeEventEmitter(SpeechRecognitionModule);

const App = () => {
  const [transcribedText, setTranscribedText] = useState('');
  const [isListening, setIsListening] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [isWaitingForKeyword, setIsWaitingForKeyword] = useState(false);
  const [logs, setLogs] = useState<string[]>([]);
  const pulseAnim = useRef(new Animated.Value(1)).current;
  const scrollViewRef = useRef<ScrollView>(null);

  useEffect(() => {
    const transcriptionSubscription = speechRecognitionEmitter.addListener(
      'onSpeechRecognized',
      (event) => {
        setTranscribedText(event.text);
      }
    );

    const logSubscription = speechRecognitionEmitter.addListener(
      'onLogMessage',
      (event) => {
        setLogs(prevLogs => [...prevLogs, event.message]);
      }
    );

    const stateChangeSubscription = speechRecognitionEmitter.addListener(
      'onStateChange',
      (event) => {
        setIsPaused(event.isPaused);
        setIsWaitingForKeyword(event.isWaitingForKeyword);
      }
    );

    return () => {
      transcriptionSubscription.remove();
      logSubscription.remove();
      stateChangeSubscription.remove();
    };
  }, []);

  useEffect(() => {
    if (isPaused) {
      Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, {
            toValue: 1.1,
            duration: 1000,
            useNativeDriver: true,
          }),
          Animated.timing(pulseAnim, {
            toValue: 1,
            duration: 1000,
            useNativeDriver: true,
          }),
        ])
      ).start();
    } else {
      pulseAnim.setValue(1);
      pulseAnim.stopAnimation();
    }
  }, [isPaused, pulseAnim]);

  useEffect(() => {
    scrollViewRef.current?.scrollToEnd({ animated: true });
  }, [logs]);

  const startListening = async () => {
    try {
      await SpeechRecognitionModule.startListening();
      setIsListening(true);
    } catch (error) {
      console.error('Error starting listening:', error);
    }
  };

  const stopListening = async () => {
    try {
      await SpeechRecognitionModule.stopListening();
      setIsListening(false);
    } catch (error) {
      console.error('Error stopping listening:', error);
    }
  };

  const pauseListening = async () => {
    try {
      await SpeechRecognitionModule.pauseListening();
    } catch (error) {
      console.error('Error pausing listening:', error);
    }
  };

  const resumeListening = async () => {
    try {
      await SpeechRecognitionModule.resumeListening();
    } catch (error) {
      console.error('Error resuming listening:', error);
    }
  };

  const clearText = async () => {
    try {
      await SpeechRecognitionModule.clearText();
      setTranscribedText('');
    } catch (error) {
      console.error('Error clearing text:', error);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Dummy Assistant</Text>

      <Animated.View
        style={[
          styles.transcriptionContainer,
          {
            transform: [{ scale: pulseAnim }],
            borderColor: isPaused ? '#FFDC00' : 'transparent',
            borderWidth: isPaused ? 2 : 0,
          }
        ]}
      >
        <Text style={styles.transcriptionText}>
          {isPaused
            ? (isWaitingForKeyword ? "Waiting for 'mark' or 'marc'..." : "Say 'resume' or 'stop'")
            : (transcribedText || "Your speech will appear here...")}
        </Text>
      </Animated.View>

      <View style={styles.buttonContainer}>
        <TouchableOpacity
          style={[
            styles.button,
            { backgroundColor: isListening ? '#FF4136' : '#0074D9' }
          ]}
          onPress={isListening ? stopListening : startListening}
        >
          <Text style={styles.buttonText}>
            {isListening ? "Stop" : "Start"}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[
            styles.button,
            { backgroundColor: isPaused ? '#2ECC40' : '#FFDC00' }
          ]}
          onPress={isPaused ? resumeListening : pauseListening}
          disabled={!isListening}
        >
          <Text style={styles.buttonText}>
            {isPaused ? "Resume" : "Pause"}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, { backgroundColor: '#B10DC9' }]}
          onPress={clearText}
        >
          <Text style={styles.buttonText}>Clear</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.logContainer}>
        <Text style={styles.logTitle}>Logs:</Text>
        <ScrollView style={styles.logScrollView} ref={scrollViewRef}>
          {logs.map((log, index) => (
            <Text key={index} style={styles.logText}>{log}</Text>
          ))}
        </ScrollView>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#F5F5F5',
  },
  title: {
    fontSize: 30,
    fontWeight: 'bold',
    fontFamily: 'Courier New',
    marginBottom: 20,
    color: '#333',
  },
  transcriptionContainer: {
    padding: 15,
    backgroundColor: 'white',
    borderRadius: 10,
    minHeight: 120,
    width: '100%',
    justifyContent: 'center',
    marginBottom: 20,
    shadowColor: "#000",
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  transcriptionText: {
    fontFamily: 'Courier New',
    fontSize: 14,
    color: '#333',
    textAlign: 'center',
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    width: '100%',
    marginBottom: 20,
  },
  button: {
    width: 80,
    height: 80,
    borderRadius: 40,
    justifyContent: 'center',
    alignItems: 'center',
    margin: 10,
    shadowColor: "#000",
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  buttonText: {
    color: 'white',
    fontFamily: 'Courier New',
    fontSize: 14,
    fontWeight: 'bold',
  },
  logContainer: {
    width: '100%',
    height: 150,
    backgroundColor: 'white',
    borderRadius: 10,
    padding: 10,
    shadowColor: "#000",
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  logTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  logScrollView: {
    flex: 1,
  },
  logText: {
    fontFamily: 'Courier New',
    fontSize: 12,
    marginBottom: 2,
  },
});

export default App;
