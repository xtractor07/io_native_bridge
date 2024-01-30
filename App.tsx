/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React, {useState} from 'react';
import {
  View,
  Text,
  Button,
  NativeModules,
  TextInput,
  StyleSheet,
} from 'react-native';

const {CustomModule} = NativeModules;

const callNativeModule = async () => {
  try {
    const response = await CustomModule.exampleMethod('React-Native');
    console.log(response);
  } catch (e) {
    console.error(e);
  }
};

const App = () => {
  // State hooks for storing title and message
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');

  // Function to handle the button press
  const handlePress = () => {
    console.log('Title:', title);
    console.log('Message:', message);
    CustomModule.createNotificationWithTitle(title, message);
  };
  return (
    <View style={styles.container}>
      <Text>Welcome to the POC!</Text>

      <TextInput
        style={styles.input}
        placeholder="Enter Title"
        value={title}
        onChangeText={setTitle} // Update the title state when the text changes
      />

      <TextInput
        style={styles.input}
        placeholder="Enter Message"
        value={message}
        onChangeText={setMessage} // Update the message state when the text changes
      />

      <Button title="Fire-Notification" onPress={handlePress} />
    </View>
  );
};

// Stylesheet for the component
const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  input: {
    height: 40,
    margin: 12,
    borderWidth: 1,
    padding: 10,
    width: '80%', // Width set to 80% of the parent container
  },
});

export default App;
