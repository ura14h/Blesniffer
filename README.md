# Bluetooth LE sniffer

A Bluetooth LE sniffer for CC2540 USB dongle and macOS.

## Usage

This is a command line utility.

```
$ Blesniffer [-c channel#] [-d device#] output.pcap
```

### Parameters

  * `-c channel#`: RF channel. The channel must be from 0 to 39. This is option parameter.
  * `output.pcap`: A name of output file which format is PCAP. If you specified '-', the program outputs captured packets to standard out.


## Requirements

* Texas Instruments CC2540EMK-USB
* macOS 10.12
* Xcode 8.1

## License

Please read [this file](LICENSE).

