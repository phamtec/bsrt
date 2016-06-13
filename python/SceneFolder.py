import os, glob

class SceneFolder:

	def __init__(self, parent, ext):
		self.ext = ext
		self.parent = parent

	def collectAllFrameFiles(self):
		os.chdir(self.parent)
		return map(self._stripExtension, glob.glob("*." + self.ext))

	def _stripExtension(self, filename):
		return os.path.splitext(filename)[0]
