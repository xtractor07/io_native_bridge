/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import React from 'react';
import {View, Text, Button, NativeModules} from 'react-native';

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
  return (
    <View style={{flex: 1, justifyContent: 'center', alignItems: 'center'}}>
      <Text>Welcome to the POC!</Text>
      <Button title="Call Native Module" onPress={callNativeModule} />
    </View>
  );
};

export default App;
