//
//  Created by merowing on 08/10/2013.
//
//
//
NSError *pixle_NSErrorMake(NSString *message, NSUInteger code, NSDictionary *aUserInfo, SEL selector) {
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:aUserInfo];
  userInfo[NSLocalizedDescriptionKey] = message;
  NSError *error = [NSError errorWithDomain:@"com.pixle.KZPropertyMapper" code:code userInfo:userInfo];

  NSLog(@"KZPropertyMapper Error: %@", error.localizedDescription);
  return error;
}