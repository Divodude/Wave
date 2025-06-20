from django.core.files.storage import Storage
from django.utils.deconstruct import deconstructible
import firebase_admin
from firebase_admin import storage as fb_storage
import logging

logger = logging.getLogger(__name__)

@deconstructible
class FirebaseStorage(Storage):
    def __init__(self, option=None):
        self._bucket = None
        
    @property
    def bucket(self):
        if self._bucket is None:
            self._bucket = fb_storage.bucket()
        return self._bucket

    def _open(self, name, mode='rb'):
        from django.core.files.base import ContentFile
        blob = self.bucket.blob(name)
        content = blob.download_as_bytes()
        return ContentFile(content)

    def _save(self, name, content):
        blob = self.bucket.blob(name)
        blob.upload_from_file(content, content_type=content.content_type)
        return name

    def delete(self, name):
        blob = self.bucket.blob(name)
        try:
            blob.delete()
        except Exception as e:
            logger.error(f"Error deleting file {name}: {e}")
            raise

    def exists(self, name):
        blob = self.bucket.blob(name)
        return blob.exists()

    def url(self, name):
        blob = self.bucket.blob(name)
        return blob.generate_signed_url(version='v4', expiration=3600, method='GET')

    def size(self, name):
        blob = self.bucket.blob(name)
        blob.reload()
        return blob.size

    def get_available_name(self, name, max_length=None):
        return name