from watchdog.events import FileSystemEventHandler

class FileSysWatcher(FileSystemEventHandler):

	def __init__(self, scene, project, files):
		self.scene = scene
		self.project = project
		self.files = files

	def on_created(self, event):
		newfiles = self.scene.collectAllFrameFiles()
		diff = list(set(newfiles) - set(self.files))
		if len(diff) > 0:
			self.project.uploadFrames(diff, self._storeFiles)

	def _storeFiles(self, project, files):
		self.files = files
