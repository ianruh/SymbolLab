//
//  File.swift
//  
//
//  Created by Ian Ruh on 5/29/20.
//

import SymbolLab
import SymbolLabTraining
import PythonKit

let plt = Python.import("matplotlib.pyplot")
let np = Python.import("numpy")

let dataWrangler = DataWrangler(emnistPath: "/Users/ianruh/Dev/SymbolLab/Data/files_emnist/", crohmePath: "/Users/ianruh/Dev/SymbolLab/Data/files_crohme/")
let imageHandler = ImageHandler(options: ImageGeneratorOptions(), dataWrangler: dataWrangler)
let tuple1 = imageHandler.string("sin")
let tuple2 = imageHandler.number(314)
let op = imageHandler.getSymbol(of: "+")
let tuple = imageHandler.compose(left: tuple1, right: tuple2, operation: op)
print(tuple.boundingBoxes)
plt.imsave("/Users/ianruh/Downloads/comp.png", tuple.image)

//print(dataWrangler.crohmeSymbols)
//plt.imsave("/Users/ianruh/Downloads/3.png", dataWrangler.getRandom(symbol: "3").astype(np.float))
