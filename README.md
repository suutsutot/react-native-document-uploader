# react-native-document-uploader

React Native Library for uploading documents

## Installation

```sh
npm install react-native-document-uploader
```

## Android compatibility

Version 0.1.6 obtains the foreground activity through `ReactApplicationContext`,
which supports React Native 0.87 without consumer-side patches. The JavaScript API
and file selection behavior are unchanged.

## Usage


```js
import { pick, PickedFile } from 'react-native-document-uploader';

const uploadedFile = await pick();
if (uploadedFile) {
    console.log('Response:', uploadedFile);
}
```


## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
