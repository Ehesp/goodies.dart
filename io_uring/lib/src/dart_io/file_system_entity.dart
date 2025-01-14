import 'dart:io';

import '../io_uring.dart';

import 'directory.dart';
import 'file.dart';
import 'link.dart';

RingBasedFile wrapFile(IOUringImpl ring, File ioFile) {
  return RingBasedFile(ring, ioFile);
}

RingBasedDirectory wrapDirectory(IOUringImpl ring, Directory ioDirectory) {
  return RingBasedDirectory(ring, ioDirectory);
}

RingBasedLink wrapLink(IOUringImpl ring, Link ioLink) {
  return RingBasedLink(ioLink, ring);
}

RingBasedFileSystemEntity wrap(IOUringImpl ring, FileSystemEntity ioEntity) {
  if (ioEntity is File) {
    return wrapFile(ring, ioEntity);
  } else if (ioEntity is Directory) {
    return wrapDirectory(ring, ioEntity);
  } else if (ioEntity is Link) {
    return wrapLink(ring, ioEntity);
  }

  throw AssertionError("Can't happen");
}

abstract class RingBasedFileSystemEntity implements FileSystemEntity {
  IOUringImpl get ring;
  FileSystemEntity get inner;
  FileSystemEntityType get type;

  FileSystemEntity wrapHere(FileSystemEntity e) {
    return wrap(ring, e);
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) {
    return inner.delete(recursive: recursive).then(wrapHere);
  }

  @override
  void deleteSync({bool recursive = false}) {
    inner.deleteSync(recursive: recursive);
  }

  @override
  Future<bool> exists() {
    return stat().then((s) => s.type == type);
  }

  @override
  bool existsSync() {
    return inner.existsSync();
  }

  @override
  bool get isAbsolute => inner.isAbsolute;

  @override
  Directory get parent => wrapDirectory(ring, inner.parent);

  @override
  String get path => inner.path;

  @override
  Future<FileSystemEntity> rename(String newPath) {
    return inner.rename(newPath).then(wrapHere);
  }

  @override
  FileSystemEntity renameSync(String newPath) {
    return wrapHere(inner.renameSync(newPath));
  }

  @override
  Future<String> resolveSymbolicLinks() {
    return inner.resolveSymbolicLinks();
  }

  @override
  String resolveSymbolicLinksSync() {
    return inner.resolveSymbolicLinksSync();
  }

  @override
  Future<FileStat> stat() {
    return ring.run(ring.stat(path));
  }

  @override
  FileStat statSync() {
    return ring.runSync(ring.stat(path));
  }

  @override
  Uri get uri => inner.uri;

  @override
  Stream<FileSystemEvent> watch(
      {int events = FileSystemEvent.all, bool recursive = false}) {
    return inner.watch(events: events, recursive: recursive);
  }
}
