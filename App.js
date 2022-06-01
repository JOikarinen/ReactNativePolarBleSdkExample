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

const Section = ({children, title}): Node => {
  const isDarkMode = useColorScheme() === 'dark';
  return (
    <View style={styles.sectionContainer}>
      <Text
        style={[
          styles.sectionTitle,
          {
            color: isDarkMode ? Colors.white : Colors.black,
          },
        ]}>
        {title}
      </Text>
      <Text
        style={[
          styles.sectionDescription,
          {
            color: isDarkMode ? Colors.light : Colors.dark,
          },
        ]}>
        {children}
      </Text>
    </View>
  );
};

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
        <Header />
        <View
          style={{
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
          }}>
          <AskPermissions />
          <Section title="Polar BLE SDK">
            <SearchForDeviceButton />
          </Section>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const AskPermissions = () => {
    if (Platform.OS === "android") {
        return (
            <Section title="Get Permissions">
                <Button title="request permissions" onPress={requestBluetoothPermission} />
            </Section>
        )
    } else {
        return null;
    }
};

const SearchForDeviceButton = () => {
  const { PolarBleSdkModule } = NativeModules;
  const onPress = () => {
    PolarBleSdkModule.searchForDevice();
  };

  return (
    <Button
      title="Search for BLE devices"
      color="#841584"
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
