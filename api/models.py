from django.db import models

# Create your models here.





class Album(models.Model):
    name = models.CharField(max_length=255)
    artist = models.CharField(max_length=255)

    def __str__(self):
        return f"{self.name} by {self.artist}"


class Music(models.Model):
    song_cover = models.ImageField(upload_to='music_covers/', null=True, blank=True)
    song = models.FileField(upload_to='music/',null=False)
    name = models.CharField(max_length=255,db_index=True)
    artist = models.CharField(max_length=255)
    duration = models.CharField(max_length=10, null=True, blank=True)
    song_album = models.ForeignKey(
        Album,
        on_delete=models.CASCADE,
        related_name='songs',  # this is the key fix
        null=True,
        blank=True
    )

    def __str__(self):
        return f"{self.name} by {self.artist}"

class MusicRoom(models.Model):
    name = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)




class AnonymousSessionUsage(models.Model):
    session_key = models.CharField(max_length=100, unique=True)
    date = models.DateField(auto_now_add=True)
    seconds_used = models.PositiveIntegerField(default=0)

    def __str__(self):
        return f"{self.session_key} - {self.date} - {self.seconds_used}s"