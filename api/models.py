from django.db import models
from django.contrib.auth.models import User

# Create your models here.


from api.firebase_ import FirebaseStorage


class Album(models.Model):
    name = models.CharField(max_length=255)
    artist = models.CharField(max_length=255)
    cover_image = models.FileField(upload_to='music_album_covers/', null=True, blank=True, storage=FirebaseStorage())

    def __str__(self):
        return f"{self.name} by {self.artist}"

    class Meta:
        ordering = ['name']  # or use ['-id'] or any other consistent field



class Music(models.Model):
    song_cover = models.ImageField(upload_to='music_covers/', null=True, blank=True, storage=FirebaseStorage())
    song = models.FileField(upload_to='music/', null=False, storage=FirebaseStorage())
    name = models.CharField(max_length=255, db_index=True)
    artist = models.CharField(max_length=255)
    duration = models.CharField(max_length=10, null=True, blank=True)
    song_album = models.ForeignKey(
        Album,
        on_delete=models.CASCADE,
        related_name='songs',
        null=True,
        blank=True
    )

    def __str__(self):
        return f"{self.name} by {self.artist}"

    class Meta:
        ordering = ['name']  # or ['-id'], or ['artist', 'name']


class MusicRoom(models.Model):
    name = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)




class AnonymousSessionUsage(models.Model):
    session_key = models.CharField(max_length=100, unique=True)
    date = models.DateField(auto_now_add=True)
    seconds_used = models.PositiveIntegerField(default=0)

    def __str__(self):
        return f"{self.session_key} - {self.date} - {self.seconds_used}s"


class SubS(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    is_active = models.BooleanField(default=False)
    plan_name = models.CharField(max_length=50, default="Free")
    started_at = models.DateTimeField(auto_now_add=True)
    def __str__(self):
        return f"{self.user.username} - {self.plan_name} - {'Active' if self.is_active else 'Inactive'}"





