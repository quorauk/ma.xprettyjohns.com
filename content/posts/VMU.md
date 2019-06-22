---
title: "Arduino Volume Meter"
date: 2019-06-22T00:22:03+01:00
---

I've recently upgraded to a Audio Technica AT2020 so I can use better headphones on my home computer. Having a freestanding microphone does have its difficulties though. Keeping track of how loud I am coming through to friends is hard when I can move away from the microphone. To solve this I built an Arduino volume meter. Here I'll go over how it works.

I wanted an excuse to write some rust and the availablity of the [winapi crate](https://crates.io/crates/winapi) seemed like a good opportunity to give it go. The crate integrates with the C++ library so there was a bit of work to do in converting some examples from [here](https://docs.microsoft.com/en-us/windows/desktop/coreaudio/peak-meters) to work in Rust. This was a bit of a pain, but after reading more documentation than I'd like to admit. We had something printing out peak values from the microphone

{{< highlight rust "linenos=table" >}}
extern crate winapi;

use winapi::um::objbase::*;
use winapi::um::mmdeviceapi::*;
use winapi::um::endpointvolume::*;
use winapi::shared::*;
use winapi::Interface;

fn get_device_enumerator() -> *mut IMMDeviceEnumerator {
    let cls_mm_device_enum : guiddef::GUID = CLSID_MMDeviceEnumerator;
    let iid_imm_device_enumerator = IMMDeviceEnumerator::uuidof();

    let mut device_enumerator : *mut IMMDeviceEnumerator = unsafe { std::mem::zeroed() };

    unsafe {
        winapi::um::combaseapi::CoCreateInstance(&cls_mm_device_enum,
            std::ptr::null_mut(),
            wtypesbase::CLSCTX_INPROC_SERVER,
            &iid_imm_device_enumerator,
            &mut device_enumerator as *mut *mut IMMDeviceEnumerator
                                    as *mut *mut winapi::ctypes::c_void);
    }
    return device_enumerator;
}

fn get_imm_device(device_enumerator : *mut IMMDeviceEnumerator) -> *mut IMMDevice {
    let mut pp_device : *mut winapi::um::mmdeviceapi::IMMDevice = unsafe { std::mem::zeroed() }; 
    unsafe {
        (*device_enumerator).GetDefaultAudioEndpoint(
            winapi::um::mmdeviceapi::eCapture,
            winapi::um::mmdeviceapi::eCommunications,
            &mut pp_device
        );
    }
    return pp_device;
}

fn get_iaudio_meter_information(pp_device : *mut IMMDevice) -> *mut IAudioMeterInformation {
    let cls_iaudio_meter_information = IAudioMeterInformation::uuidof();

    let mut input_device : *mut IAudioMeterInformation = unsafe { std::mem::zeroed() };

    unsafe {
        (*pp_device).Activate(
            &cls_iaudio_meter_information,
            wtypesbase::CLSCTX_INPROC_SERVER,
            std::ptr::null_mut(),
            &mut input_device as *mut *mut winapi::um::endpointvolume::IAudioMeterInformation
                                as *mut *mut winapi::ctypes::c_void); 
    }
    return input_device;
}

pub fn get_audio_meter_information() -> *mut IAudioMeterInformation {
    unsafe { CoInitialize(std::ptr::null_mut()) };
    let device_enumerator : *mut IMMDeviceEnumerator = get_device_enumerator();
    let pp_device : *mut IMMDevice = get_imm_device(device_enumerator);
    return get_iaudio_meter_information(pp_device);
}

fn main() {
    let input_device = get_audio_meter_information()
    let mut peak : f32 = 0.0;
    loop {
        unsafe { (*input_device).GetPeakValue(&mut peak) };
        println!("{}", peak);  
    }
}
{{< / highlight >}}

This got me a fair way to the goal. We now have audio levels printing to the console. Now to hook it up to an arduino.

![Example image](/VMU-arduino-600px.jpg)

This is a really simple circuit, its just a bunch of leds, one per digital pin, the positive pin goes to a digital pin via a 220k ohm resistor. The negative pin goes to ground.

We need to edit our Rust code now, as well as flash some code onto the Arduino. 

The Arduino code is relatively simple, it will connect to the serial port, then light up the number of leds we send over the serial port.

{{< highlight ino "linenos=table" >}}
#define PIN_NUM 10

int pins[PIN_NUM] = {2,3,4,5,6,7,8,9,10,11};
int inByte;         // incoming serial byte

void setup() {
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
}


void loop() {
  // if we get a valid byte, read analog ins:
  if (Serial.available() > 0) {
    // get incÚoming byte:
    int incomingData = Serial.parseInt();
    if (incomingData <= PIN_NUM && incomingData >= 0) {
      for (int i = 0; i < incomingData; i++) {
        analogWrite(pins[i], 255);
      }
      for (int i = incomingData; i < PIN_NUM; i++) {
        analogWrite(pins[i], 0);
      }
    }
  }
}
{{< / highlight >}}

Testing this out with the serial monitor, it displays the *volume* rather nicely. Now we just need to connect to it from the Rust code and we are done.

I am using the [SerialPort crate](https://crates.io/crates/serialport) here to do most of the heavy lifting. I have also refactored most of the windows API specific code out to a seperate file.

{{< highlight rust "linenos=table" >}}
extern crate serialport;
extern crate winapi;

use std::io::{self, Write};

use serialport::*;
use std::time::Duration;

mod windows;

const NUM_PINS : f32 = 10 as f32;
const PORT_NAME: &str = "COM3";

fn get_settings() -> SerialPortSettings {
    let mut settings: SerialPortSettings = Default::default();
    settings.timeout = Duration::from_millis(100);
    settings.baud_rate = 9600;
    return settings
}

fn connected(port : &mut serialport::SerialPort, input_device : *mut winapi::um::endpointvolume::IAudioMeterInformation) {
    let mut x : u32;
    loop {
        let mut peak : f32 = 0.0;
        unsafe { (*input_device).GetPeakValue(&mut peak) };

        x = (peak * NUM_PINS) as u32;
        let s : String = x.to_string() + "\n";  
        match port.write(s.as_bytes()) {
            Ok(_) => {
                std::io::stdout().flush().unwrap();
            }
            Err(ref e) if e.kind() == io::ErrorKind::TimedOut => {
                eprint!("Timeout: {:?}", e);
                return;
            }
            Err(e) => {
                eprintln!("{:?}", e);
                return;
            }
        }
        std::thread::sleep(Duration::from_millis(100));
    }
}


fn main() {

    let input_device = windows::get_audio_meter_information();
    let settings = get_settings();

    loop {
        match serialport::open_with_settings(&PORT_NAME, &settings) {
            Ok(mut port) => {
                println!("Opened serial device: {}", PORT_NAME);
                connected(&mut *port, input_device);
            }
            Err(e) => {
                eprintln!("Failed to open port: {}", e);
                std::thread::sleep(Duration::from_secs(5));
            }
        }
    }
}

{{< / highlight >}}

And there we have it. The project is finished and working great. The code here definitely leaves a lot to be desired, but i'm pretty happy with the result for a few hours work.

You can find all the source code from the final result [here](https://github.com/quorauk/arduino-audio-meter). Thanks for reading.