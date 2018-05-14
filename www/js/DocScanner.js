"use strict";
var argscheck = require('cordova/argscheck');
var exec = require('cordova/exec');

var clamp = function(val,minVal,maxVal,defaultVal){
    if(typeof defaultVal !== "undefined") {
        defaultVal = Math.min(Math.max(minVal, defaultVal), maxVal)
        if(val > maxVal) val = defaultVal;
        if(val < minVal) val = defaultVal;
    }else val = Math.min(Math.max(minVal, val), maxVal);
    return val;
}

var docScannerExport = {};

docScannerExport.takePicture = function(successCallback, errorCallback, options) {
    // argscheck.checkArgs('fFO', 'Camera.getPicture', arguments);
    var getValue = argscheck.getValue;

    /*
    quality: 60, //possible
    sourceType: navigator.camera.PictureSourceType.CAMERA, //?
    destinationType: navigator.camera.DestinationType.FILE_URI, //?
    encodingType: Camera.EncodingType.JPEG, //?
    correctOrientation: true, //No Idea
    saveToPhotoAlbum: saveToPhotoAlbum, //maybe
    targetWidth: 512, //possible
    targetHeight: 512, //possible
    allowEdit: allowEdit //maybe later, not yet

    */

    var quality = clamp(getValue(options.quality, 80),0,100,80); //So the user doesn't go under 0% or over 100%
    var targetWidth = getValue(options.targetWidth, 0);
    var targetHeight = getValue(options.targetHeight, 0);
    var correctOrientation = !!options.correctOrientation;
    // var destinationType = getValue(options.destinationType, Camera.DestinationType.FILE_URI);
    // var sourceType = getValue(options.sourceType, Camera.PictureSourceType.CAMERA);
    // var encodingType = getValue(options.encodingType, Camera.EncodingType.JPEG);
    // var mediaType = getValue(options.mediaType, Camera.MediaType.PICTURE);
    // var allowEdit = !!options.allowEdit;
    // var saveToPhotoAlbum = !!options.saveToPhotoAlbum;
    // var popoverOptions = getValue(options.popoverOptions, null);
    // var cameraDirection = getValue(options.cameraDirection, Camera.Direction.BACK);


    var args = [quality, targetWidth, targetHeight, correctOrientation]
    // var args = [quality, destinationType, sourceType, targetWidth, targetHeight, encodingType, mediaType, allowEdit, correctOrientation, saveToPhotoAlbum, popoverOptions, cameraDirection];

    // exec(successCallback, errorCallback, "DocScanner", "takePicture", args);


    exec(successCallback, errorCallback, "DocScanner", "takePicture", args);

};

docScannerExport.isActive = function(){
    //TODO write code here
    //XXX is this needed?
}
module.exports = docScannerExport;
