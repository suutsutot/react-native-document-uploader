import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export class PickedFile {
  uri: string;
  name: string;
  type: string;
  size: number;

  constructor(uri: string, name: string, type: string, size: number) {
    this.uri = uri;
    this.name = name;
    this.type = type;
    this.size = size;
  }
}

export interface Spec extends TurboModule {
  pick(): Promise<PickedFile | null>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('DocumentUploader');
