import math
import random
from datetime import datetime

import amo
from amo.utils import slugify
from bandwagon.models import Collection, CollectionAddon, FeaturedCollection

from .translations import generate_translations


def create_collection(application):
    """Create a Collection for the given `application`."""
    data = {
        'type': amo.COLLECTION_NORMAL,
        'application': application,
        'name': 'Collection %s' % abs(hash(datetime.now())),
        'addon_count': random.randint(200, 2000),
        'subscribers': random.randint(1000, 5000),
        'monthly_subscribers': random.randint(100, 500),
        'weekly_subscribers': random.randint(10, 50),
        'upvotes': random.randint(100, 500),
        'downvotes': random.randint(100, 500),
        'listed': True,
    }
    c = Collection(**data)
    c.slug = slugify(data['name'])
    c.rating = (c.upvotes - c.downvotes) * math.log(c.upvotes + c.downvotes)
    c.created = c.modified = datetime(2014, 10, 27, random.randint(0, 23),
                                      random.randint(0, 59))
    c.save()
    return c


def generate_collection(addon, app=None):
    """
    Generate a Collection, a CollectionAddon and a FeaturedCollection
    for the given `addon` related to the optional `app`.

    """
    if app is None:  # This is a theme.
        application = None
    else:
        application = app.id

    c = create_collection(application=application)
    generate_translations(c)
    CollectionAddon.objects.create(addon=addon, collection=c)
    if app is not None:  # Useless for themes.
        FeaturedCollection.objects.create(application=application,
                                          collection=c)
