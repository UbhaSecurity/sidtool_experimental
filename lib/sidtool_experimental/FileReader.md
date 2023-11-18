# FileReader Class in Sidtool Module

The `FileReader` class is part of the `Sidtool` Ruby module and is responsible for reading and interpreting SID music files.

## Class Attributes

The class has several read-only attributes:

- `format`: The format of the SID file.
- `version`: The version of the SID file.
- `init_address`: The initial address in the SID file.
- `play_address`: The play address in the SID file.
- `songs`: The number of songs in the SID file.
- `start_song`: The starting song in the SID file.
- `name`: The name of the SID file.
- `author`: The author of the SID file.
- `released`: The release date of the SID file.
- `data`: The data of the SID file.

## Class Methods

### `self.read(path)`
Reads a SID file from a given path. It performs various checks and reads metadata as well as the actual data.

- Validates the file size, format, version, data offset, and load address.
- Reads the SID file properties: `init_address`, `play_address`, `songs`, `start_song`, `name`, `author`, and `released`.
- Extracts the data from the SID file.

### `initialize(format:, version:, init_address:, play_address:, songs:, start_song:, name:, author:, released:, data:)`
Initializes an instance of the `FileReader` class with the given parameters.

### Private Methods
- `self.read_word(bytes)`: Reads a word from a byte sequence.
- `self.read_null_terminated_string(bytes)`: Reads a null-terminated string.
- `self.read_bytes(bytes)`: Converts byte data into an array of integers.

## Example Usage

```ruby
module Sidtool
  class FileReader
    # ... class definition ...

    def self.read(path)
      # ... implementation ...
    end

    # ... other methods ...
  end
end

# Using the FileReader
file_reader = Sidtool::FileReader.read('path/to/sid/file')
