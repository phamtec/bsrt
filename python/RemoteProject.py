
class RemoteProject:

	def __init__(self, be, project, host):
		self.be = be
		self.project = project
		self.host = host

	def deleteServerFrames(self, cb):
		cb(self)

	def uploadFrames(self, frames, cb):
		result = self.be.post("progress", data={'project': self.project, 'host': self.host, 'frames': ", ".join(frames), 'socketid': self.be.socketId})
		if result:
			cb(self, frames)
