# Stop repeating  your data parsing code in iOS apps. 
Data parsing is one of most common tasks we need to do in our apps, yet still majority of people do this parsing by hand, always repeating the same code for each class they need to map.

Usual parsing requires this steps:
* make sure you translate NSNull to nil and not crash
* gracefully handle optional params
* do type conversions
* data format validation

## Why Property Mapper?
There are libraries helping with that like Mantle, RESTKit and many more… But I wanted something that's self contained, easy to change / remove and requires minimal amount of code.

I've created **Property Mapper** as part of working on [Foldify][2], a simple self contained solution that allows you to specify mapping between data you receive and data representation you have in your application... with some additional features, like **type boxing**, **validation**.

I don't like passing around JSON so I write parsing on top of native objects like NSDictionary/NSArray. 
If you get data as JSON just write a simple category that transforms JSON to native objects using NSJSONSerialization.


## What's new in 2.0?
* New property syntax (old one still works) that allows you to get  compile errors when you misspell property names.
* Introduced concept of validators, chain-able.

Time to implement this changes was sponsored by [The App Business][1].

## Example usage
Let's assume you have object like this:
````objc
@interface TestObject : NSObject
@property(nonatomic, strong) NSURL *contentURL;
@property(nonatomic, strong) NSURL *videoURL;
@property(nonatomic, strong) NSNumber *type;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *uniqueID;

@end
````

and you receive data from server in this format:
````objc
@{
  @"videoURL" : @"http://test.com/video.mp4", 
	@"name" : @"Some Cool Video", 
	@"videoType" : [NSNull null], 
	@"sub_object" : @{
			@"title" : @616,
			@"arbitraryData" : @"data"
	}
}
````
this is the code you would write in your parsing code:
````objc
[KZPropertyMapper mapValuesFrom:dictionary toInstance:self usingMapping:@{
   @"videoURL" : KZBox(URL, contentURL),
     @"name" : KZProperty(title),
     @"videoType" : KZProperty(type),
     @"sub_object" : @{
         @"title" : KZProperty(uniqueID)
         }
    
  }];
````
Quite obvious what it does but in case you are confused, it will translate videoURL string to contentURL NSURL object, it will also grab title from sub_object and assign it to uniqueID. It also handles NSNull.

## Advanced usage
Let's now change our mind and decide that we want our type property to be typedef enumeration, it's quite easy with KZPropertyMapper, change type mapping to following and add following method:
````objc
@"videoType" : KZCall(videoTypeFromString:, type),

//! implemented on instance you are parsing
- (id)videoTypeFromString:(NSString *)type
{
  if ([type isEqualToString:@"shortVideo"]) {
    return @(VideoTypeShort);
  }

  return @(VideoTypeLong);
}
```` 
Done. KVC should also take care of escaping NSNumber into int if your property uses primitive type. Same approach will work for sub-object instances or anything that you can assign to property.

## Validations
You can also validate your server data before mapping it:
````objc
[KZPropertyMapper mapValuesFrom:dictionary toInstance:self usingMapping:@{
    @"videoURL" : KZBox(URL, contentURL).isRequired().min(10),
    @"name" : KZProperty(title).lengthRange(5, 12),
    @"videoType" : KZProperty(type),
    @"sub_object" : @{
      @"title" : KZProperty(uniqueID),
    },
  }];
````
Validators can be chained together, you can specify as many as you wish for each field, validation happens on source data before mapping happens.

If validation fails mapValues will return NO as a result, and you can use expanded method to get list of validation errors.

Any validation errors will prevent mapping, as data might be corrupted and we don't want partially updated data.

### Built-in validations
#### Strings
* isRequired
* matchesRegEx
* length
* minLength
* maxLength
* lengthRange
* oneOf
* equalTo

#### Numbers
* min
* max
* range

If you want more you can add validations as categories on KZPropertyDescriptor, check sample code to see how it's done, it's extremely simple.

### Referencing arrays items
If your data comes to you in ordered array instead of dictionaries you can reference that as well:
````objc
sourceData = @{@"sub_object_array" : @[@"test", @123]}

@{@"sub_object_array" : @{@1 : KZProperty(uniqueID)}

```` 
This will grab first item from sub_object_array and assign it to uniqueID. It also works recursively.


### Expanding boxing capabilities
You can expand boxing capabilities across whole application easily, just add category on KZPropertyMapper that implements methods like this:
````objc
+ (id)boxValueAsType:(id)value
{
	//! your boxing
}
````
Now you can use @Type mapping everywhere in your code.

# Installing
Use CocoaPods.
Or just add KZPropertyMapper folder to your project, make sure you enable ARC on this files.

# Final note
Unit tests should serve as documentation. Default boxing types include @URL and @Date. 

[Follow me on twitter][7]

 [1]: http://theappbusiness.com
 [2]: http://foldifyapp.com
 [7]: http://twitter.com/merowing_
