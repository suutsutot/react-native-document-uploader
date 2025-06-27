import DocumentUploader, { PickedFile } from './NativeDocumentUploader';

export function pick(): Promise<PickedFile | null> {
  return DocumentUploader.pick();
}

export { PickedFile };
