/**
 * Sample Polar BLE SDK app
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow strict-local
 */

import React from 'react';
import type {Node} from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  useColorScheme,
  View,
  Button,
  PermissionsAndroid,
  Platform
} from 'react-native';

import {
  Colors,
  DebugInstructions,
  Header,
  LearnMoreLinks,
  ReloadInstructions,
} from 'react-native/Libraries/NewAppScreen';

import { NativeModules } from 'react-native';
import colors from './assets/colors/colors';

const App: () => Node = () => {
  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <ScrollView 
        contentInsetAdjustmentBehavior="automatic"
        style={backgroundStyle}>
        
        <View style={{
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
        }}>
          <View style={styles.sectionContainer}>
            <Text style={[styles.sectionTitle,
                {
                  color: isDarkMode ? Colors.white : Colors.black,
                },]}>Polar BLE SDK Example</Text>
              <AskPermissions />
              <PolarBleSdkCommands />
            </View>
          </View>
        </ScrollView>
      </SafeAreaView>
      );
};

const AskPermissions = () => {
 const isDarkMode = useColorScheme() === 'dark';
    if (Platform.OS === "android") {
        return (
          <View style={styles.sectionContainer}>
            <Text style={[ styles.sectionTitle,
              {
                color: isDarkMode ? Colors.white : Colors.black,
              },
              ]}>Get Permissions
              </Text>
            <View style={{margin:10}}/>
            <Button
              title="Get Permissions"
              color="#008080"
              onPress={requestBluetoothPermission}
            />
          </View>
        )
    } else {
        return null;
    }
};

const PolarBleSdkCommands = () => {
 const isDarkMode = useColorScheme() === 'dark';
        return (
        <View style={styles.sectionContainer}>
          <Text style={[ styles.sectionTitle,
          {
            color: isDarkMode ? Colors.white : Colors.black,
          },
          ]}>Polar BLE SDK commands</Text>
          <View style={{margin:10}}/>
          <SearchForDeviceButton />
          <View style={{margin:5}}/>
          <ConnectToDeviceButton />
          <View style={{margin:5}} />
          <StartEcgStreamButton />
          <View style={{margin:5}}/>
        </View>
         )
};

const SearchForDeviceButton = () => {
  const { PolarBleSdkModule } = NativeModules;
  const onPress = () => {
    PolarBleSdkModule.searchForDevice();
  };

  return (
    <Button
      title="Search for BLE devices"
      color={colors.button}
      onPress={onPress}
    />
  );
};

const ConnectToDeviceButton = () => {
  const { PolarBleSdkModule } = NativeModules;
  const onPress = () => {
    PolarBleSdkModule.connectToDevice('968BEA2E');
  };

  return (
    <Button
      title="Connect to BLE device"
      color={colors.button}
      onPress={onPress}
    />
  );
};

const StartEcgStreamButton = () => {
  const { PolarBleSdkModule } = NativeModules;
  const onPress = () => {
    PolarBleSdkModule.startEcgStream('968BEA2E');
  };

  return (
    <Button
      title="Start ECG stream"
      color={colors.button}
      onPress={onPress}
    />
  );
};

const requestBluetoothPermission = async () => {
    try {
          if (Platform.Version >= 31) {
              const granted = await PermissionsAndroid.requestMultiple(
                  [PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
                  PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT]
              ).then((result) => {
                  if (result['android.permission.BLUETOOTH_SCAN']
                   && result['android.permission.BLUETOOTH_CONNECT'] === 'granted') {
                      console.log("BLE permissions granted");
                  } else {
                      console.log("BLE permission denied");
                  }
              });
          } else {
              const granted = await PermissionsAndroid.requestMultiple(
                  [PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION]
              ).then((result) => {
                  if (result['android.permission.ACCESS_FINE_LOCATION'] === 'granted') {
                      console.log("BLE permissions granted");
                  } else {
                      console.log("BLE permission denied");
                  }
              });
          }
    } catch (err) {
      console.warn(err);
    }
};

const styles = StyleSheet.create({
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
  },
  highlight: {
    fontWeight: '700',
  },
});

export default App;
