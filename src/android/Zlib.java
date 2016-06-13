package com.apreta.plugin;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import java.util.zip.Inflater;
import java.util.zip.Deflater;
import java.util.zip.DataFormatException;
import java.util.ArrayList;

public class Zlib extends CordovaPlugin {

    private ArrayList<Inflater> inflaters;
    private ArrayList<Deflater> deflaters;
    public static final int MAX_STREAM = 4;

    public Zlib() {
        inflaters = new ArrayList<Inflater>(MAX_STREAM);
        deflaters = new ArrayList<Deflater>(MAX_STREAM);
        for (int i=0; i<MAX_STREAM; i++) {
            inflaters.add(null);
            deflaters.add(null);
        }
    }


    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) throws JSONException {

        switch (action) {
            case "deflate": {
                int stream = data.optInt(0);
                JSONArray jsData = data.getJSONArray(1);
                JSONArray out = this.deflate(stream, jsData);
                callbackContext.success(out);
                return true;
            }
            case "inflate": {
                int stream = data.optInt(0);
                JSONArray jsData = data.getJSONArray(1);
                try {
                    JSONArray out = this.inflate(stream, jsData);
                    callbackContext.success(out);
                } catch (DataFormatException ex) {
                    callbackContext.error("Data error in ZLIB stream");
                }
                return true;
            }
            case "reset": {
                int stream = data.optInt(0);
                this.reset(stream);
                callbackContext.success();
                return true;
            }
        }
        return false;
    }

    public JSONArray deflate(int stream, JSONArray in) throws JSONException {
        Deflater deflater = this.deflaters.get(stream);
        if (deflater == null) {
            deflater = new Deflater();
            deflaters.set(stream, deflater);
        }

        byte[] originalBytes = new byte[in.length()];
        for (int i=0; i<in.length(); i++) {
            int data = in.optInt(i); 
            originalBytes[i] = (byte)(data > 127 ? data - 256 : data);
        }

        deflater.setInput(originalBytes);

        byte[] compressedBytes = new byte[originalBytes.length + 128];

        int byteCount = deflater.deflate(compressedBytes, 0, compressedBytes.length, Deflater.SYNC_FLUSH);

        JSONArray out = new JSONArray();
        for (int i=0; i<byteCount; i++) {
            byte data = compressedBytes[i];
            out.put((int)(data < 0 ? 256 + data : data));
        }

        return out;
    }

    public JSONArray inflate(int stream, JSONArray in) throws DataFormatException, JSONException {
        Inflater inflater = this.inflaters.get(stream);
        if (inflater == null) {
            inflater = new Inflater();
            inflaters.set(stream, inflater);
        }

        byte[] compressedBytes = new byte[in.length()];
        for (int i=0; i<in.length(); i++) {
            int data = in.optInt(i); 
            compressedBytes[i] = (byte)(data > 127 ? data - 256 : data);
        }
        inflater.setInput(compressedBytes, 0, compressedBytes.length);

        byte[] decompressedBytes = new byte[compressedBytes.length*10];

        JSONArray out = new JSONArray();
        while (inflater.getRemaining() > 0) {
            int decompressedCount = inflater.inflate(decompressedBytes);
            for (int i=0; i<decompressedCount; i++) {
                byte data = decompressedBytes[i];
                out.put((int)(data < 0 ? 256 + data : data));
            }
        }

        return out;
    }

    public void reset(int stream) {
        this.inflaters.set(stream, null);
        this.deflaters.set(stream, null);

        /* The reset API doesn't seem to have the effect we're looking for.
        Inflater inflater = this.inflaters.get(stream);
        if (inflater != null) {
            inflater.reset();
        }
        */
    }
}
