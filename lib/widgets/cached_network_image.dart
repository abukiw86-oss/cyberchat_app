import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/rooms_cache_service.dart';

class CachedNetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final String roomname;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedNetworkImageWidget({
    Key? key,
    required this.imageUrl,
    required this.roomname,
    this.width = 50,
    this.height = 50,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ??
          Container(
            color: Colors.grey.withOpacity(0.1),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ff00)),
              ),
            ),
          ),
      errorWidget: (context, url, error) => errorWidget ??
          Container(
            color:  Colors.grey.withOpacity(0.1), 
            child:Center(
              child:Text(roomname.substring(0,1) ,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 23
              ),
            )
            )
          ),
      cacheManager: RoomCacheService.imageCache,
    );
  }
}