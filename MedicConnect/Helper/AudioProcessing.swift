//
//  AudioProcessing.swift
//  RecordingSplicer
//
//  Created by Alex Crowley on 11/05/2018.
//

import Foundation
import AVFoundation


/// ExtAudioFile API error definition (Swift exception wrapper for low level C API error codes)
class ExtAudioFileError: Error {
    private var error: OSStatus /// raw ExtAudioFile API error code
    private var errorDetails: String /// high level error details
    
    init(error: OSStatus, errorDetails: String?) {
        self.error = error
        self.errorDetails = errorDetails ?? "Unknown Error"
    }
    
    /// If the specified ExtAudioFile API error code represents an error, throw a high level exception with the error details
    static func throwOnError(error: OSStatus, errorDetails: String) throws {
        if error != noErr {
            throw ExtAudioFileError(error: error, errorDetails: errorDetails)
        }
    }
}


/// Audio processing functionality
class AudioProcessing {

    /// Insert a recording into another recording at specified point ('punch in' functionality)
    /// Supports mono/stereo files
    ///
    /// Uses the Core Audio Extended Audio File Services for 'Punch In' insert functionality
    /// [links](https://developer.apple.com/documentation/audiotoolbox/extended_audio_file_services)
    ///
    /// - parameters:
    ///   - urlRecording: Path to original recording
    ///   - urlRecordingInsert: Path to recording to be inserted ('punch in')
    ///   - urlResult: Path to result file (created on success)
    ///   - insertPoint: Insert point in seconds ('punch in point')
    /// - returns: true on success (result file was created), false on failure (result file was not created)
    static func insert(urlRecording: URL, urlRecordingInsert: URL, urlResult: URL, insertPoint: TimeInterval) -> Bool {
        var success = false
        
        print("insert \"\(urlRecordingInsert.lastPathComponent)\" into \"\(urlRecording.lastPathComponent)\" at \(insertPoint) seconds")
    
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: urlRecording.path) || !fileManager.fileExists(atPath: urlRecordingInsert.path) {
            print("abort insert, recording files not present")
            return false
        }

        var fileRecording : ExtAudioFileRef? = nil // original recording
        var fileRecordingInsert : ExtAudioFileRef? = nil // recording to insert at insertPoint seconds
        var fileResult : ExtAudioFileRef? = nil // result (file created if insert successful)
        
        do {
            var size:UInt32 = 0 // required by ExtAudioFile API
            
            // Define formats for reading/writing data
            var formatRecording : AudioStreamBasicDescription = AudioStreamBasicDescription() // recording format
            var formatRecordingInsert : AudioStreamBasicDescription = AudioStreamBasicDescription() // recording insert format, expected to be same as formatRecording
            var formatClient : AudioStreamBasicDescription = AudioStreamBasicDescription() // client format, audio is streamed from the recording files using this format (raw PCM)
            
            
            // --- Extract the required information from the recording files ---
            
            // Recording: open
            try ExtAudioFileError.throwOnError(error: ExtAudioFileOpenURL(urlRecording as CFURL, &fileRecording), errorDetails: "Recording: Open")
            
            // Recording: file type
            var fileIdRecording:AudioFileID? // get a handle to the file, so the type can be requested
            size = UInt32(MemoryLayout.stride(ofValue: fileIdRecording))
            try ExtAudioFileError.throwOnError(error: ExtAudioFileGetProperty(fileRecording!, kExtAudioFileProperty_AudioFile, &size, &fileIdRecording),
                                               errorDetails: "Recording: file ID")
            
            var fileTypeRecording:AudioFileTypeID = 0
            size = UInt32(MemoryLayout.stride(ofValue: fileTypeRecording))
            try ExtAudioFileError.throwOnError(error: AudioFileGetProperty(fileIdRecording!, kAudioFilePropertyFileFormat, &size, &fileTypeRecording),
                                               errorDetails: "Recording: file type")
            
            // Recording: file format
            size = UInt32(MemoryLayout.stride(ofValue: formatRecording))
            try ExtAudioFileError.throwOnError(error: ExtAudioFileGetProperty(fileRecording!, kExtAudioFileProperty_FileDataFormat, &size, &formatRecording),
                                               errorDetails: "Recording file: format")
            
            // Recording: num frames
            var numFramesRecording:Int64 = 0
            size = UInt32(MemoryLayout.stride(ofValue: numFramesRecording))
            try ExtAudioFileError.throwOnError(error: ExtAudioFileGetProperty(fileRecording!, kExtAudioFileProperty_FileLengthFrames, &size, &numFramesRecording),
                                               errorDetails: "Recording: num frames")
            
            
            // Insert recording: open
            try ExtAudioFileError.throwOnError(error: ExtAudioFileOpenURL(urlRecordingInsert as CFURL, &fileRecordingInsert), errorDetails: "Insert recording: Open")
            
            // Insert recording: file type
            var fileIdRecordingInsert:AudioFileID? // get a handle to the file, so the type can be requested
            size = UInt32(MemoryLayout.stride(ofValue: fileIdRecordingInsert))
            try ExtAudioFileError.throwOnError(error: ExtAudioFileGetProperty(fileRecordingInsert!, kExtAudioFileProperty_AudioFile, &size, &fileIdRecordingInsert),
                                               errorDetails: "Insert recording: file ID")
            
            var fileTypeRecordingInsert:AudioFileTypeID = 0
            size = UInt32(MemoryLayout.stride(ofValue: fileTypeRecordingInsert))
            try ExtAudioFileError.throwOnError(error: AudioFileGetProperty(fileIdRecordingInsert!, kAudioFilePropertyFileFormat, &size, &fileTypeRecordingInsert),
                                               errorDetails: "Insert recording: file type")
            
            // Insert recording: file format
            size = UInt32(MemoryLayout.stride(ofValue: formatRecordingInsert))
            try ExtAudioFileError.throwOnError(error: ExtAudioFileGetProperty(fileRecordingInsert!, kExtAudioFileProperty_FileDataFormat, &size, &formatRecordingInsert),
                                               errorDetails: "Insert recording file: format")
            
            // Insert recording: num frames
            var numFramesRecordingInsert:Int64 = 0
            size = UInt32(MemoryLayout.stride(ofValue: numFramesRecordingInsert))
            try ExtAudioFileError.throwOnError(error: ExtAudioFileGetProperty(fileRecordingInsert!, kExtAudioFileProperty_FileLengthFrames, &size, &numFramesRecordingInsert),
                                               errorDetails: "Insert recording: num frames")
            
            // Expect recording and recording insert to be same format
            if fileTypeRecording != fileTypeRecordingInsert {
                throw ExtAudioFileError(error: 0, errorDetails: "Invalid media")
            }
            
            
            // --- Configure ExtAudioFile for reading audio ---
            
            // Indicate to ExtAudioFile API which format to read samples (raw, signed PCM, interleaved)
            size = UInt32(MemoryLayout.stride(ofValue: formatClient))
            bzero(&formatClient, Int(size))
            formatClient.mSampleRate = formatRecording.mSampleRate
            formatClient.mFormatID = kAudioFormatLinearPCM
            formatClient.mChannelsPerFrame = formatRecording.mChannelsPerFrame
            formatClient.mBitsPerChannel = 16
            formatClient.mBytesPerPacket = 2 * formatClient.mChannelsPerFrame
            formatClient.mBytesPerFrame = 2 * formatClient.mChannelsPerFrame
            formatClient.mFramesPerPacket = 1
            formatClient.mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger
            
            // Recording: set read format (raw PCM)
            size = UInt32(MemoryLayout.stride(ofValue: formatClient))
            try ExtAudioFileError.throwOnError(error: ExtAudioFileSetProperty(fileRecording!, kExtAudioFileProperty_ClientDataFormat, size, &formatClient),
                                               errorDetails: "Recording: read format")
            
            // Recording insert: set read format (raw PCM)
            try ExtAudioFileError.throwOnError(error: ExtAudioFileSetProperty(fileRecordingInsert!, kExtAudioFileProperty_ClientDataFormat, size, &formatClient),
                                               errorDetails: "Insert recording: read format")
            
            
            // --- Create result file ---
            
            // Result: create file (imply same format as recording)
            try ExtAudioFileError.throwOnError(error: ExtAudioFileCreateWithURL(urlResult as CFURL, kAudioFileM4AType, &formatRecording, nil, AudioFileFlags.eraseFile.rawValue, &fileResult), errorDetails: "Result: create file")
            
            // Result: set write format (raw PCM)
            try ExtAudioFileError.throwOnError(error: ExtAudioFileSetProperty(fileResult!, kExtAudioFileProperty_ClientDataFormat, size, &formatClient),
                                               errorDetails: "Result: write format")
            
            
            // --- Stream the data from the recording files into the result file, respecting the insert point ---
            
            var eofRecording:Bool = false // whether end of recording file has been reached
            var eofRecordingInsert:Bool = false // whether end of recording insert file has been reached
            
            let bufferSize : UInt32 = 16384 // read buffer size
            var buffer = [UInt8](repeating: 0, count: Int(bufferSize)) // read buffer
            var bufferDummy = [UInt8](repeating: 0, count: Int(bufferSize)) // dummy read buffer
            
            var frame:UInt64 = 0 // current frame
            let frameInsert:UInt64 = min(UInt64(ceil(Double(insertPoint) * formatRecording.mSampleRate)), UInt64(numFramesRecording)) // frame at which to insert second recording
            
            while !eofRecording || !eofRecordingInsert {
                let isInserting:Bool = !eofRecordingInsert && (frame >= frameInsert)
                
                var readBuffer = AudioBufferList( // for reading/writing data
                    mNumberBuffers: 1,
                    mBuffers: AudioBuffer(
                        mNumberChannels: formatRecording.mChannelsPerFrame,
                        mDataByteSize: UInt32(buffer.count),
                        mData: &buffer
                    )
                )
                
                var numFrames:UInt32 = bufferSize // attempt to read a full buffer, unless insert point is reached

                if !isInserting {
                    if !eofRecordingInsert && ((frame + UInt64(numFrames)) >= frameInsert) { // whether this buffer exceeds the insert point
                        numFrames = UInt32(frameInsert - frame) // only read upto insert point
                    }
                    
                    // Read: recording
                    try ExtAudioFileError.throwOnError(error: ExtAudioFileRead(fileRecording!, &numFrames, &readBuffer),
                                                       errorDetails: "Recording: read data") // numFrames will be updated with actual number of frames read
                }
                else {
                    // Read: recording insert
                    try ExtAudioFileError.throwOnError(error: ExtAudioFileRead(fileRecordingInsert!, &numFrames, &readBuffer),
                                                       errorDetails: "Recording insert: read data") // numFrames will be updated with actual number of frames read
                    
                    // Dummy read: recording (to maintain sync)
                    var dummyBuffer = AudioBufferList(
                        mNumberBuffers: 1,
                        mBuffers: AudioBuffer(
                            mNumberChannels: formatRecording.mChannelsPerFrame,
                            mDataByteSize: UInt32(bufferDummy.count),
                            mData: &bufferDummy
                        )
                    )
                    
                    var numFramesDummy:UInt32 = numFrames
                    var numFramesReadDummy:UInt32 = 0
                    while !eofRecording && (numFramesReadDummy < numFrames) {
                        try ExtAudioFileError.throwOnError(error: ExtAudioFileRead(fileRecording!, &numFramesDummy, &dummyBuffer),
                                                           errorDetails: "Recording: read data (dummy)") // dummy read (discard)
                        if numFramesDummy > 0 { // got some data
                            numFramesReadDummy += numFramesDummy
                        }
                        else {
                            eofRecording = true
                        }
                    }
                }
                
                if numFrames > 0 { // got some data
                    try ExtAudioFileError.throwOnError(error: ExtAudioFileWrite(fileResult!, numFrames, &readBuffer),
                                                       errorDetails: "Write data") // write the data to the result file
                    
                    frame += UInt64(numFrames)
//                  print("wrote \(numFrames) frames from \(isInserting ? "insert" : "original") recording, total: \(frame)")
                }
                else { // reached end of file
                    if isInserting {
                        eofRecordingInsert = true
                    }
                    else {
                        eofRecording = true
                    }
                }
            }
            
            
            // --- Success, tidy up ---
            ExtAudioFileDispose(fileRecording!)
            ExtAudioFileDispose(fileRecordingInsert!)
            ExtAudioFileDispose(fileResult!)
            
            print("recording insert successful")
            
            success = true
        }
        catch {
            print("recording insertion failed")
            
            // Error, tidy up
            if fileRecording != nil {
                ExtAudioFileDispose(fileRecording!)
            }
            
            if fileRecordingInsert != nil {
                ExtAudioFileDispose(fileRecordingInsert!)
            }
            
            if fileResult != nil {
                ExtAudioFileDispose(fileResult!)
            }
            
            if fileManager.fileExists(atPath: urlResult.path) {
                do {
                    try fileManager.removeItem(at: urlResult)
                }
                catch {
                    print("error deleting aborted result file")
                }
            }
        }
        
        return success
    }
}

