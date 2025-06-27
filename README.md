# react-native-document-uploader

React Native Library for uploading documents

## Installation

```sh
npm install react-native-document-uploader
```

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
