//
//  BuildAction.swift
//  CI2Go
//
//  Created by Atsushi Nagase on 1/1/16.
//  Copyright © 2016 LittleApps Inc. All rights reserved.
//

import RealmSwift
import RxSwift
import ObjectMapper
import Carlos
#if os(iOS)
import CryptoSwift
#endif

class BuildAction: Object, Mappable, Comparable {
    static let cache = MemoryCacheLevel<String, NSString>() >>> DiskCacheLevel()
    lazy var disposeBag: DisposeBag = { DisposeBag() }()
    enum Status: String {
        case Success = "success"
        case Failed = "failed"
        case Canceled = "canceled"
        case Timedout = "timedout"
        case Running = "running"
    }
    dynamic var bashCommand = ""
    dynamic var buildStep: BuildStep?
    dynamic var stepNumber: Int = 0
    dynamic var command = ""
    dynamic var endedAt: NSDate?
    dynamic var exitCode: Int = 0
    dynamic var hasOutput = false
    dynamic var id = ""
    dynamic var isCanceled = false
    dynamic var isContinue = false
    dynamic var isFailed = false
    dynamic var isInfrastructureFail = false
    dynamic var isParallel = false
    dynamic var isTimedout = false
    dynamic var isTruncated = false
    dynamic var name = ""
    dynamic var nodeIndex: Int = 0
    dynamic var outputURLString: String?
    dynamic var runTimeMillis: Int = 0
    dynamic var source = ""
    dynamic var startedAt: NSDate?
    dynamic var rawStatus: String?
    dynamic var actionType = ""
    dynamic var output = ""

    required convenience init?(_ map: Map) {
        self.init()
        mapping(map)
    }

    var actionName: String {
        return (actionType.componentsSeparatedByString(":").last ?? actionType).humanize
    }

    var pusherChannelName: String? {
        guard let bc = buildStep?.build?.pusherChannelName else { return nil }
        return "\(bc)@\(nodeIndex)"
    }

    var status: Status? {
        get {
            if let rawStatus = rawStatus {
                return Status(rawValue: rawStatus)
            }
            return nil
        }
        set(value) {
            rawStatus = value?.rawValue
        }
    }

    func mapping(map: Map) {
        isTruncated <- map["truncated"]
        nodeIndex <- map["index"]
        isParallel <- map["parallel"]
        isFailed <- map["failed"]
        isInfrastructureFail <- map["infrastructure_fail"]
        name <- map["name"]
        bashCommand <- map["bash_command"]
        rawStatus <- map["status"]
        isTimedout <- map["timedout"]
        isContinue <- map["continue"]
        actionType <- map["type"]
        outputURLString <- map["output_url"]
        exitCode <- map["exit_code"]
        isCanceled <- map["canceled"]
        stepNumber <- map["step"]
        runTimeMillis <- map["run_time_millis"]
        hasOutput <- map["has_output"]
        endedAt <- (map["end_time"], JSONDateTransform())
        startedAt <- (map["start_time"], JSONDateTransform())
    }

    func updateId() {
        #if os(iOS)
        if let stepId = self.buildStep?.id where !stepId.isEmpty && id.isEmpty {
            id = "\(stepId)@\(actionType):\(name.md5()):\(nodeIndex)"
        }
        #endif
    }

    override class func primaryKey() -> String {
        return "id"
    }

    var outputURL: NSURL? {
        get {
            if let outputURLString = outputURLString {
                return NSURL(string: outputURLString)
            }
            return nil
        }
        set(value) {
            outputURLString = value?.absoluteString
        }
    }

    private lazy var logSource: Variable<NSAttributedString> = {
        return Variable<NSAttributedString>(NSAttributedString(string: ""))
    }()

    var log: Observable<NSAttributedString> {
        let src = self.logSource
        self.downloadLog().subscribeNext { log in
            dispatch_async(dispatch_queue_create("attributed-text", nil), {
                let s = ColorScheme()
                let astr = s.ansiHelper.attributedStringWithANSIEscapedString(log)
                dispatch_async(dispatch_get_main_queue(), {
                    src.value = astr
                })
            })
        }.addDisposableTo(disposeBag)
        return src.asObservable()
    }

    func appendLog(str: String) {
        dispatch_async(dispatch_queue_create("attributed-text", nil), {
            let src = NSMutableAttributedString(attributedString: self.logSource.value)
            let s = ColorScheme()
            let astr = s.ansiHelper.attributedStringWithANSIEscapedString(str)
            src.appendAttributedString(astr)
            let res = src.copy() as! NSAttributedString
            dispatch_async(dispatch_get_main_queue(), {
                self.logSource.value = res
            })
        })
    }

    override static func ignoredProperties() -> [String] {
        return ["status", "outputURL", "logSource", "log", "cache", "disposeBag", "log"]
    }

    func dup() -> BuildAction {
        let dup = BuildAction()
        dup.bashCommand = bashCommand
        dup.buildStep = buildStep
        dup.stepNumber = stepNumber
        dup.command = command
        dup.endedAt = endedAt
        dup.exitCode = exitCode
        dup.hasOutput = hasOutput
        dup.id = id
        dup.isCanceled = isCanceled
        dup.isContinue = isContinue
        dup.isFailed = isFailed
        dup.isInfrastructureFail = isInfrastructureFail
        dup.isParallel = isParallel
        dup.isTimedout = isTimedout
        dup.isTruncated = isTruncated
        dup.name = name
        dup.nodeIndex = nodeIndex
        dup.outputURLString = outputURLString
        dup.runTimeMillis = runTimeMillis
        dup.source = source
        dup.startedAt = startedAt
        dup.rawStatus = rawStatus
        dup.actionType = actionType
        dup.output = output
        return dup
    }

    override func isEqual(object: AnyObject?) -> Bool {
        return self.id == (object as? BuildAction)?.id
    }
}

func ==(lhs: BuildAction, rhs: BuildAction) -> Bool {
    return lhs.id == rhs.id
}

func >(lhs: BuildAction, rhs: BuildAction) -> Bool {
    return lhs.id > rhs.id
}

func <(lhs: BuildAction, rhs: BuildAction) -> Bool {
    return lhs.id < rhs.id
}

func >=(lhs: BuildAction, rhs: BuildAction) -> Bool {
    return lhs.id >= rhs.id
}

func <=(lhs: BuildAction, rhs: BuildAction) -> Bool {
    return lhs.id <= rhs.id
}
