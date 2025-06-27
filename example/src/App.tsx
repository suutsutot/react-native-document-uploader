import { useState } from 'react';
import { Text, View, StyleSheet, Button, useColorScheme } from 'react-native';
import { pick, PickedFile } from 'react-native-document-uploader';

export default function App() {
  const scheme = useColorScheme();
  const textColor = scheme === 'dark' ? 'white' : 'black';
  const [file, onFileChange] = useState<PickedFile | null>(null);
  const uploadFile = async () => {
    try {
      const uploadedFile = await pick();
      if (uploadedFile) {
        console.log('Response:', uploadedFile);
        onFileChange(uploadedFile);
      } else {
        onFileChange(null);
      }
    } catch (error) {
      onFileChange(null);
      console.log(error);
    }
  };
  return (
    <View style={styles.container}>
      <Button onPress={uploadFile} title="Upload"></Button>
      <Text style={{ color: textColor }}>Result:</Text>
      {file && (
        <>
          <Text style={{ color: textColor }}>URI: {file.uri}</Text>
          <Text style={{ color: textColor }}>Name: {file.name}</Text>
          <Text style={{ color: textColor }}>Type: {file.type}</Text>
          <Text style={{ color: textColor }}>Size: {file.size}</Text>
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
