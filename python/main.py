import os, sys, glob
import httplib
import requests
import socket
from datetime import datetime
from backend import *
from RemoteProject import RemoteProject
from SceneFolder import SceneFolder
from FileSysWatcher import FileSysWatcher
from GUI import ModalDialog, Label, Button, TextField, ListButton, Row, Column, Frame, Font, FileDialogs, ScrollableView
from GUI.StdFonts import system_font
from GUI.Files import FileType, DirRef, FileRef
from watchdog.observers import Observer

#be = ProdBackend()
be = LocalBackend()

italic_font = Font("Avenir", system_font.size, ['italic'])
normal_font = Font("Avenir", system_font.size)
label_width = 100
field_width = 400

class MainWindow(ModalDialog):

	def __init__(self):
		ModalDialog.__init__(self)

		self.username = TextField(text = be.username(), width = field_width, font = normal_font)
		self.password = TextField(text = be.password(), width = field_width, password = True, font = normal_font)
		self.login_button = Button("Login", action = "login", font = normal_font)
		self.serverBox = Column([
			Label("Server", font = italic_font),
			Row([Label("Username:", width = label_width, font = normal_font), self.username]),
			Row([Label("Password:", width = label_width, font = normal_font), self.password]),
			self.login_button
		])

		self.projects = ListButton(titles = [" "], values = [" "], width = field_width, font = normal_font)
		self.host = TextField(text = socket.gethostname(), width = field_width, font = normal_font)
		if len(sys.argv) == 2:
			 dir = sys.argv[1]
		else:
			dir = os.path.dirname(sys.argv[0])
		self.folder = TextField(text = os.path.abspath(dir), width = field_width, font = normal_font)
		self.setfolder_button = Button("Set", action = "setfolder", font = normal_font)
		self.extension = TextField(text = "jpg", width = field_width, font = normal_font)
		self.settingsBox = Column([
			Label("Settings", font = italic_font),
			Row([Label("Projects:", width = label_width, font = normal_font), self.projects]),
			Row([Label("Host:", width = label_width, font = normal_font), self.host]),
			Row([Label("Folder:", width = label_width, font = normal_font), self.folder, self.setfolder_button]),
			Row([Label("Extension:", width = label_width, font = normal_font), self.extension])
		])

		self.enableBox(self.serverBox, True)
		self.enableBox(self.settingsBox, False)

		self.msgs = TextField(text = "", width = field_width, font = normal_font)
		self.msgsBox = Column([
			Label("Messages", font = italic_font),
			self.msgs
		])

		self.start_button = Button("Start", action = "start", font = normal_font)
		self.stop_button = Button("Stop", action = "stop", font = normal_font)
		self.quit_button = Button("Quit", action = "quit", font = normal_font)

		self.add(Column([
			self.serverBox,
			self.settingsBox,
			self.start_button,
			self.stop_button,
			self.msgsBox,
			self.quit_button
		], padding = (20, 0)))

		self.shrink_wrap(padding = (20, 20))

	def _enableBox(self, contents, enabled):
		for i in contents:
			if hasattr(i, 'contents'):
				self._enableBox(i.contents, enabled)
			else:
				i.enabled = enabled

	def enableBox(self, box, enabled):
		self._enableBox(box.contents, enabled)

	def msg(self, msg):
		m = "%s: %s" % (str(datetime.now()), msg)
		self.msgs.text = m
		print m

	def login(self):
		if be.login(self.username.text, self.password.text):
			json = be.get("users/me")
			if json:
				json = be.get("projects")
				if json:
					self.projectData = json
					p = map(lambda e: e['name'], self.projectData)
					self.projects.titles = p
					self.projects.values = p
					self.projects.value = p[0]
					self.enableBox(self.serverBox, False)
					self.enableBox(self.settingsBox, True)
					self.msg("Logged in.")

	def start(self):
		self._startListening()
		self._startTracking()

	def stop(self):
		self._stopTracking()

	def setfolder(self):
		result = FileDialogs.request_old_directory("Open Directory:", default_dir = DirRef(self.folder.text))
		self.folder.text = "%s/%s" % (result.dir.path, result.name)

	def getProjectId(self, name):
		return filter(lambda e: e['name'] == name, self.projectData)[0]['_id']

	def _startTracking(self):
		project = RemoteProject(be, self.getProjectId(self.projects.value), self.host.text)
		project.deleteServerFrames(self._startTracking2)

	def _startTracking2(self, project):
		scene = SceneFolder(self.folder.text, self.extension.text)
		self.files = scene.collectAllFrameFiles()
		if len(self.files) > 0:
			project.uploadFrames(self.files, self.watchFolder)
		else:
			self.watchFolder(project, [])

	def _stopTracking(self):
		if self.observer:
			self.observer.stop()

	def _startListening(self):
		be.socket.on('progress', self._onProgress)
		be.socket.on('command', self._onCommand)
		be.socket.on('id', self._onId)
		be.socket.wait()

	def _onProgress(self):
		""

	def _onCommand(self):
		""

	def _onId(self, data):
		be.socketId = data
		be.socket.emit('openDocument', { 'id': self.getProjectId(self.projects.value), 'initials': '', 'userid': ''})

	def watchFolder(self, project, files):
		self.observer = Observer()
		scene = SceneFolder(self.folder.text, self.extension.text)
		self.observer.schedule(FileSysWatcher(scene, project, self.files), self.folder.text, recursive=False)
		self.observer.start()

	def quit(self):
		self.dismiss(True)

dlog = MainWindow()
dlog.present()

